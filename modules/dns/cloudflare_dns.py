#!/usr/bin/env python3
import json
import subprocess
import sys
import requests
import os
from typing import List, Optional

def get_tailscale_ip() -> Optional[str]:
    """Get the current Tailscale IPv4 address."""
    try:
        result = subprocess.run(
            ["tailscale", "ip", "-4"],
            capture_output=True,
            text=True,
            check=True
        )
        ip = result.stdout.strip().split('\n')[0]
        return ip if ip else None
    except (subprocess.CalledProcessError, FileNotFoundError, IndexError):
        return None

def read_api_token(token_file: str) -> str:
    """Read the API token from the secrets file and ensure it's clean."""
    try:
        with open(token_file, 'r') as f:
            # Aggressively strip all whitespace, including newlines
            token = f.read().strip()
            if not token: # Check if token is empty after stripping
                raise ValueError("API token file is empty or contains only whitespace")
            return token
    except IOError as e:
        print(f"Error reading API token file {token_file}: {e}")
        sys.exit(1)
    except ValueError as e:
        print(f"Error with API token: {e}")
        sys.exit(1)

def test_api_connection(zone_id: str, api_token: str) -> bool:
    """Test the API connection and permissions."""
    print("Testing Cloudflare API connection...")
    url = f"https://api.cloudflare.com/client/v4/user/tokens/verify"
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }

    try:
        response = requests.get(url, headers=headers, timeout=30)
        
        if response.status_code == 200:
            data = response.json()
            if data.get("success", False):
                zone_name = data.get("result", {}).get("name", "unknown")
                print(f"✓ API connection successful. Zone: {zone_name}")
                return True
            else:
                print("✗ API returned success=false:")
                for error in data.get("errors", []):
                    print(f"  {error}")
                return False
        else:
            print(f"✗ API connection failed with status {response.status_code}")
            try:
                error_data = response.json()
                print(f"Error details: {json.dumps(error_data, indent=2)}")
            except:
                print(f"Raw response: {response.text}")
            return False
            
    except requests.RequestException as e:
        print(f"✗ Network error testing API: {e}")
        return False

def get_dns_record(domain: str, zone_id: str, api_token: str) -> Optional[dict]:
    """Get the current DNS A record for a domain."""
    url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records"
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }
    params = {"name": domain, "type": "A"}

    try:
        response = requests.get(url, headers=headers, params=params, timeout=30)
        
        if response.status_code == 200:
            data = response.json()
            if data.get("success", False):
                records = data.get("result", [])
                return records[0] if records else None
            else:
                print(f"Cloudflare API error for {domain}:")
                for error in data.get("errors", []):
                    print(f"  {error}")
                return None
        else:
            print(f"HTTP {response.status_code} error getting DNS record for {domain}:")
            try:
                error_data = response.json()
                print(f"  {json.dumps(error_data, indent=2)}")
            except:
                print(f"  Raw response: {response.text}")
            return None
        
    except requests.RequestException as e:
        print(f"Network error getting DNS record for {domain}: {e}")
        return None

def create_dns_record(domain: str, ip: str, zone_id: str, api_token: str, ttl: int = 300) -> bool:
    """Create a new DNS A record."""
    url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records"
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }
    data = {
        "type": "A",
        "name": domain,
        "content": ip,
        "ttl": ttl,
        "proxied": False
    }

    print(f"Creating DNS record: {json.dumps(data, indent=2)}")

    try:
        response = requests.post(url, headers=headers, json=data, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            if result.get("success", False):
                print(f"Successfully created DNS record for {domain} -> {ip}")
                return True
            else:
                print(f"Error creating DNS record for {domain}:")
                for error in result.get("errors", []):
                    print(f"  {error}")
                return False
        else:
            print(f"HTTP {response.status_code} error creating DNS record for {domain}:")
            try:
                error_data = response.json()
                print(f"  {json.dumps(error_data, indent=2)}")
            except:
                print(f"  Raw response: {response.text}")
            return False
            
    except requests.RequestException as e:
        print(f"Network error creating DNS record for {domain}: {e}")
        return False

def update_dns_record(domain: str, record_id: str, new_ip: str, zone_id: str, api_token: str) -> bool:
    """Update a DNS A record with a new IP address."""
    url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records/{record_id}"
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }
    data = {"content": new_ip}

    try:
        response = requests.patch(url, headers=headers, json=data, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            if result.get("success", False):
                print(f"Successfully updated {domain} -> {new_ip}")
                return True
            else:
                print(f"Error updating {domain}:")
                for error in result.get("errors", []):
                    print(f"  {error}")
                return False
        else:
            print(f"HTTP {response.status_code} error updating {domain}:")
            try:
                error_data = response.json()
                print(f"  {json.dumps(error_data, indent=2)}")
            except:
                print(f"  Raw response: {response.text}")
            return False
            
    except requests.RequestException as e:
        print(f"Network error updating {domain}: {e}")
        return False

def update_domain(domain: str, tailscale_ip: str, zone_id: str, api_token: str) -> bool:
    """Update a single domain's DNS record if needed, or create it if it doesn't exist."""
    print(f"Processing domain: {domain}")
    
    # Get current DNS record
    record = get_dns_record(domain, zone_id, api_token)
    
    if record is None:
        # No existing record, create a new one
        print(f"No A record found for {domain}, creating new record...")
        return create_dns_record(domain, tailscale_ip, zone_id, api_token)
    
    # Record exists, check if update is needed
    record_id = record.get("id")
    current_ip = record.get("content")
    
    if current_ip == tailscale_ip:
        print(f"IP for {domain} is already up to date ({current_ip})")
        return True

    print(f"Updating {domain}: {current_ip} -> {tailscale_ip}")
    return update_dns_record(domain, record_id, tailscale_ip, zone_id, api_token)

def main():
    """Main function to update all configured domains."""
    # Get Tailscale IP
    tailscale_ip = get_tailscale_ip()
    if not tailscale_ip:
        print("Error: Could not get Tailscale IP address")
        sys.exit(1)
    
    print(f"Current Tailscale IP: {tailscale_ip}")

    # Read configuration from environment variables
    zone_id = os.environ.get("ZONE_ID")
    api_token_file = os.environ.get("API_TOKEN_FILE")
    domains_json = os.environ.get("DOMAINS")

    if not zone_id or not api_token_file or not domains_json:
        print("Error: Missing required environment variables")
        print(f"ZONE_ID: {'✓' if zone_id else '✗'}")
        print(f"API_TOKEN_FILE: {'✓' if api_token_file else '✗'}")
        print(f"DOMAINS: {'✓' if domains_json else '✗'}")
        sys.exit(1)

    try:
        domains = json.loads(domains_json)
    except json.JSONDecodeError as e:
        print(f"Error parsing domains JSON: {e}")
        sys.exit(1)

    print(f"Zone ID: {zone_id}")
    print(f"Domains to process: {domains}")

    # Read API token
    api_token = read_api_token(api_token_file)
    
    # Test API connection first
    if not test_api_connection(zone_id, api_token):
        print("Failed to connect to Cloudflare API. Please check:")
        print("1. Your API token has the correct permissions (Zone:DNS:Edit)")
        print("2. Your Zone ID is correct")
        print("3. The contents of your age secret file for any extra whitespace/newlines")
        sys.exit(1)

    # Update all domains
    success_count = 0
    total_count = len(domains)
    
    for domain in domains:
        if update_domain(domain, tailscale_ip, zone_id, api_token):
            success_count += 1

    print(f"DNS update completed: {success_count}/{total_count} domains processed successfully")
    
    if success_count < total_count:
        sys.exit(1)

if __name__ == "__main__":
    main()
