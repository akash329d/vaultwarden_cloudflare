import secrets
import string

import CloudFlare


def picker(title, items, display_props):
    picker_string = [f"\nAvailable {title}s"]
    for i, item in enumerate(items):
        props_repr = ", ".join(map(lambda prop: f"{prop}: {item[prop]}", display_props))
        picker_string.append(f"{i+1}. {props_repr}")
    print("\n".join(picker_string))

    num = -1
    valid_nums = list(map(str, range(1, len(items) + 1)))
    while True:
        num = input(f"{title} to use (choose number): ")
        if num not in valid_nums:
            print("Invalid Choice")
        else:
            break
    print()
    return items[int(num) - 1]


def generate_alphanum_secret(length):
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for i in range(length))


def main():
    api_token, email, tunnel_name = (
        input("Cloudflare API Token: "),
        input("Cloudflare Email: "),
        input("Desired Tunnel Name: "),
    )
    cf = CloudFlare.CloudFlare(email=email, token=api_token)

    account = picker("Account", cf.accounts.get(), ["id", "name"])
    zone = picker("Zone", cf.zones.get(), ["id", "name"])
    domain = input("Domain to configure (must be Zone domain or subdomain): ")

    tunnel_secret = generate_alphanum_secret(48)


    print("Attempting to create tunnel")
    tunnel = cf.accounts.cfd_tunnel.post(
        account["id"],
        data={
            "config_src": "cloudflare",
            "name": tunnel_name,
            "tunnel_secret": tunnel_secret,
        },
    )

    config = cf.accounts.cfd_tunnel.configurations.put(
        account['id'],
        tunnel["id"],
        data={
            "config": {
                "ingress": [
                    {
                        "service": "ws://vaultwarden:3012",
                        "hostname": domain,
                        "path": "notifications/hub",
                        "originRequest": {},
                    },
                    {
                        "service": "http://vaultwarden:80",
                        "hostname": domain,
                        "originRequest": {},
                    },
                    {"service": "http_status:404", "originRequest": {}},
                ]
            }
        },
    )

    print("Successfully created tunnel via Cloudflare API!")

    print(f"Attempting to create DNS CNAME record for Zone (proxy to {tunnel['id']}.cfargotunnel.com)")

    cname = cf.zones.dns_records.post(
        zone['id'],
        data={
            "content": f'{tunnel["id"]}.cfargotunnel.com',
            "name": domain,
            "type": "CNAME",
            "proxied": True,
        },
    )
    print("Please verify success manually, no verification built into script")
    print("Tunnel Token (for .env): ", tunnel["token"])


if __name__ == "__main__":
    main()
