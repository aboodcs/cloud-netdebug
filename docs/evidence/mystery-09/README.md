# Evidence for Mystery 09 — Source-Dependent Connectivity

> Evidence status: not executed. This directory contains collection instructions only.

Related guide: [`09-source-dependent-connectivity.md`](../../mysteries/09-source-dependent-connectivity.md)

This exercise uses the intended architecture rather than an injected fault. Compare direct laptop access to the private `target-01` address with access from `admin-01` to that same address.

## Required captures

- Provider, region, timestamp, and sanitized instance identifiers.
- Confirmation that `target-01` has a private address and no public address.
- Laptop route decision and TCP/22/SSH result for the target private address.
- `admin-01` route decision and TCP/22/SSH result for the same target address.
- Cloud rules showing laptop-to-admin and admin-to-target access boundaries.
- Optional successful `ProxyJump` result, if actually tested.
- Any VPN or local `10.0.0.0/16` overlap that changes the expected failure mode.

## Command checklist

Run on the laptop:

```bash
date --iso-8601=seconds
ip route get <target-private-ip>
nc -vz -w 5 <target-private-ip> 22
ssh -vvv -o ConnectTimeout=10 <target-user>@<target-private-ip>
```

Run on `admin-01` against the same address:

```bash
date --iso-8601=seconds
ip route get <target-private-ip>
nc -vz -w 5 <target-private-ip> 22
ssh -vvv -o ConnectTimeout=10 <target-user>@<target-private-ip>
```

If tested from the laptop, record the exact jump-host command separately:

```bash
ssh -J <admin-user>@<admin-public-ip> <target-user>@<target-private-ip>
```

Do not publish private keys, credentials, or an unsanitized public administration address.
