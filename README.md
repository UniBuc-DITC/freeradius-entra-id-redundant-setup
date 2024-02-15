# RADIUS protocol with Microsoft Entra ID back end

## Description

This repository documents how to allow [RADIUS](https://en.wikipedia.org/wiki/RADIUS)-based clients to authenticate against a [Microsoft Entra ID](https://www.microsoft.com/en-us/security/business/identity-access/microsoft-entra-id) (formerly Azure AD) tenant with the help of [FreeRADIUS](https://freeradius.org/).

## Tools used

- [FreeRADIUS](https://freeradius.org/) as a RADIUS server (with the [FreeRADIUS Docker image](https://hub.docker.com/r/freeradius/freeradius-server) used as base);

- [Redis](https://redis.io/) for caching credentials (in the form of salted, secure hashes);

- [`freeradius-oauth2-perl`](https://github.com/jimdigriz/freeradius-oauth2-perl/tree/master) module for authenticating users against a Microsoft Entra ID tenant;
