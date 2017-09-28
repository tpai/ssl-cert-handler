SSL Cert Handler
===

HTTP Challenge handler for request SSL certificate from certbot.

## Usage

**MAKE SURE THE VALIDATION URL IS READY FOR VERTIFICATION.**

```
demo.com/.well-known/acme-challenge/:token
sample.com/.well-known/acme-challenge/:token
example.com/.well-known/acme-challenge/:token
```

Then create domain list for requesting SSL certificate in `domains/`.

Filename: myList

```
demo.com
sample.com
example.com
```

**Request cert**

```
yarn auth domains/myList
```

If success, certificate will present in `cert/demo.com/`.

**Renew cert**

```
yarn renew
```
