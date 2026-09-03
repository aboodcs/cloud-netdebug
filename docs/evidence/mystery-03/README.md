# Evidence for Mystery 03 — IP Works, DNS Fails

> Evidence status: not executed. This directory contains collection instructions only.

Related guide: [`03-ip-works-dns-fails.md`](../../mysteries/03-ip-works-dns-fails.md)

Collect every comparison from the same host. The baseline must first prove that the selected name and its verified address reach the intended endpoint before DNS traffic is blocked locally.

## Required captures

- Timestamp, provider, source host, tested name, and its verified baseline address.
- Baseline name resolution and application request.
- Resolver configuration before and during the fault.
- The temporary `netdebug_m3` nftables table and its UDP/TCP port 53 rules.
- IP-based control result and name-based failure result.
- Resolver and application results after deleting the temporary table.

## Command checklist

```bash
date --iso-8601=seconds
hostname
getent ahosts <verified-test-name>
dig +time=2 +tries=1 <verified-test-name>
resolvectl status
ip route get <verified-baseline-address>
curl -v --connect-timeout 10 https://<verified-test-name>/
sudo nft list table inet netdebug_m3
```

Also capture the exact IP-based control command established during the baseline. Preserve whether the error was a DNS failure, connection timeout, refusal, or HTTP/TLS response; those outcomes are not interchangeable.

Suggested phases are `baseline`, `dns-blocked`, and `rollback`. Do not create output files until the commands have actually been run.
