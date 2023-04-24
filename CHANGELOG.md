# Changelog

## Version 3.1

- Move Docker images to Docker Hub and disable build to save time
- Remove Express installer (most users prefer having a choice)
- Code refactor and cleanup

## Version 3.0

- Add Hysteria proxy
- Add NaiveProxy
- Add user management
- Add backup/restore
- Add an unattended WordPress installation as decoy website
- Move from Docker repo to Dockerfile builds for more privacy clarity
- Require less individual subdomains
- Permanent and protected user share links page
- Paranoid protection: Blocking every incoming connection except from Iran and Cloudflare subnets

## Version 2.0

- Add DNS over HTTPS/TLS support
- Add support for GeoIP or DNS filtering
- Major overhaul of the user experience
- Added SNI entry retention and editing
- Fixed many 🪲

## Version 1.4

- Make compatible transports [gRPC, Websocket] CDN ready
- Let the user return from domain prompt without entring anything

## Version 1.3

- Fixed bugs
- Break down submenus
- Add more network tuning parameters
- Remove useless functions for a leaner codebase

## Version 1.2

- Moved PUBLIC_IP detection to the dependent function for faster start time
- Improved README

## Version 1.1

- Added a cronjob to keep xt_geoip updated
- Removed unnecessary package requirements such as lsb_release
- Reverted UUID generation to Kernel virtual device
- Cleanup and misc enhancements

## Version 1.0

- Initial release
