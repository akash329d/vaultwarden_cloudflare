# Vaultwarden Self Hosted on Oracle Cloud and Cloudflare Tunnel

This is a setup to run Vaultwarden on Oracle Cloud. Uses cloudflare tunnel to expose Vaultwarden instance which eliminates any need for https certificate setup or ddns. 

Requires a Cloudflare managed DNS site. I used a [1.111B Class XYZ](https://gen.xyz/1111b) domain which costs $1/year indefinitely, making this a very cost effective solution.

Based off of [bitwarden_gcloud](https://github.com/dadatuputi/bitwarden_gcloud) which contains setup instructions that are very similar to the setup needed for this setup. I used the Oracle Cloud Free Tier - `VM.Standard.A1.Flex` with 4 CPUs and 24GB of memory. Keep in mind that resources using the free trial will be automatically deleted at the end of the trial when your account permanantly switches to the free tier, so MAKE SURE to have a backup or wait until your account is on the permanant free tier.

By default, the docker-compose is setup to run the `utils/backup.sh` script within the rclone container every day. This will backup the vaultwarden database to Google Drive or any RClone supported endpoint. 

Additionally, includes a python script `utils/create_tunnel.py` that uses the Cloudflare API to initially configure the Cloudflare Tunnel with the correct port settings (forwarding the correct websocket and http ports). This is required since currently the web interface does not support configuring the web socket protocol, however once it's setup you can change the settings via the Web UI.  