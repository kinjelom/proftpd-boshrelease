# BOSH Release for ProFTPD

## Test it

Ports:
```bash
ss -ltnp | grep proftpd
LISTEN 0      4096         0.0.0.0:1021       0.0.0.0:*    users:(("proftpd",pid=67322,fd=0))        
LISTEN 0      4096         0.0.0.0:2222       0.0.0.0:*    users:(("proftpd",pid=67322,fd=1))        
LISTEN 0      4096         0.0.0.0:9273       0.0.0.0:*    users:(("proftpd",pid=67321,fd=6)) 
```

Install FTP client:
```bash
apt install lftp
```


### FTPS

The FTPS server certificate:
```bash
openssl s_client -connect q-s0.proftpd.default.proftpd-rnd.bosh:2121 -starttls ftp -showcerts </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -fingerprint -sha256
```

Test with the server's certificate verification:
```bash
lftp -e "set ssl:ca-file /var/vcap/jobs/proftpd/config/mod_tls/ca.crt; open -u test-user,change-me q-s0.proftpd.default.proftpd-rnd.bosh:2121; pwd; debug 1; ls; bye"
```

Test without the server's certificate verification:
```bash
lftp -e "set ssl:verify-certificate no; open -u test-user,change-me 127.0.0.1:2121; pwd; debug 1; ls; bye"
```

Test ACLS:
```bash

lftp -e "set ssl:verify-certificate no; open -u test-user,change-me 127.0.0.1:2121; put -O . /dev/null -o test-acls-1.txt; ls -l; bye"
  
lftp -e "set ssl:verify-certificate no; open -u test-user-ro,change-me 127.0.0.1:2121; ls -l; rm test-acls-1.txt; bye"

lftp -e "set ssl:verify-certificate no; open -u test-user-ro,change-me 127.0.0.1:2121; put -O . /dev/null -o test-acls-2.txt; bye"

lftp -e "set ssl:verify-certificate no; open -u test-user,change-me 127.0.0.1:2121; ls -l; rm test-acls-1.txt; bye"
  
```

### SFTP

```bash
lftp -e "set sftp:auto-confirm yes; open -u test-user,change-me sftp://127.0.0.1:2222; pwd; debug 1; ls; bye"

```
