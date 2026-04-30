#!/usr/bin/env python3
import argparse
import json
import os
import sys

import pika


DEFAULT_URL = "amqp://radicale:radicale-rabbitmq@rabbitmq:5672/"
DEFAULT_QUEUE = "radicale"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Consume Radicale RabbitMQ hook messages and print prettified JSON."
    )
    parser.add_argument(
        "--url",
        default=os.environ.get("RADICALE_RABBITMQ_URL", DEFAULT_URL),
        help="AMQP URL. Defaults to RADICALE_RABBITMQ_URL or the Radicale queue URL.",
    )
    parser.add_argument(
        "--queue",
        default=os.environ.get("RADICALE_RABBITMQ_QUEUE", DEFAULT_QUEUE),
        help="Queue name. Defaults to RADICALE_RABBITMQ_QUEUE or 'radicale'.",
    )
    parser.add_argument(
        "--once",
        action="store_true",
        help="Print one message and exit.",
    )
    return parser.parse_args()


def print_message(body: bytes) -> None:
    text = body.decode("utf-8", errors="replace")
    try:
        message = json.loads(text)
    except json.JSONDecodeError:
        print(text)
        print(file=sys.stderr)
        print("Message was not valid JSON; printed raw body.", file=sys.stderr)
        return

    print(json.dumps(message, indent=2, sort_keys=True))
    print()
    sys.stdout.flush()


def main() -> int:
    args = parse_args()
    connection = pika.BlockingConnection(pika.URLParameters(args.url))
    channel = connection.channel()
    channel.queue_declare(
        queue=args.queue,
        durable=True,
        arguments={"x-queue-type": "classic"},
    )
    channel.basic_qos(prefetch_count=1)

    print(f"Listening on RabbitMQ queue '{args.queue}'...", file=sys.stderr)
    print("Press Ctrl-C to stop.", file=sys.stderr)

    def on_message(ch, method, _properties, body: bytes) -> None:
        print_message(body)
        ch.basic_ack(delivery_tag=method.delivery_tag)
        if args.once:
            ch.stop_consuming()

    channel.basic_consume(queue=args.queue, on_message_callback=on_message)

    try:
        channel.start_consuming()
    except KeyboardInterrupt:
        print("Stopping.", file=sys.stderr)
    finally:
        if connection.is_open:
            connection.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
