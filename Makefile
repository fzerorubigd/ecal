export ROOT:=$(realpath $(dir $(firstword $(MAKEFILE_LIST))))
PIIP?=192.168.1.162
PIUSER?=forud
BUNDLE?=http://192.168.1.211:8000/bundle.zip

PIHOST:=$(PIUSER)@$(PIIP)
PICMD:=ssh $(PIHOST) -o LogLevel=QUIET -t
PIROOT:="/home/$(PIUSER)/ecal"
PISYNC:=rsync -avz --update -e ssh
GPG:=gpg --no-default-keyring --keyring $(ROOT)/keyring/trust.db --pinentry-mode=loopback 

setup-root:
	@$(PICMD) mkdir -p $(PIROOT)

setup-render:
	@$(PISYNC) $(ROOT)/render $(PIHOST):$(PIROOT)/

setup: setup-root setup-render
	
clean-screen: setup
	@$(PICMD) python $(PIROOT)/render/ecal.py --clear x x 

$(ROOT)/keyring/.pass:
	openssl rand -out $@ -base64 100

define KEYCOMMAND
%echo "Generating ECC keys (sign & encr) with no-expiry"
  Key-Type: EDDSA
    Key-Curve: ed25519
  Subkey-Type: ECDH
    Subkey-Curve: cv25519
  Name-Email: $(PIHOST)
  Expire-Date: 0
  # Now, let's do a commit here, so that we can later print "done" :-)
  %commit
%echo Done
endef
export KEYCOMMAND

$(ROOT)/keyring/keycommands:
	echo "$$KEYCOMMAND" > $@

$(ROOT)/keyring/$(PIHOST).public.key:
	@$(GPG) --export --armor $(PIHOST) > $@

$(ROOT)/keyring/$(PIHOST).private.key:
	@$(GPG) --passphrase-file $(ROOT)/keyring/.pass --export-secret-keys --armor $(PIHOST) > $@

keys: $(ROOT)/keyring/$(PIHOST).public.key $(ROOT)/keyring/$(PIHOST).private.key
	@cat $(ROOT)/keyring/$(PIHOST).public.key 

setup-keys: $(ROOT)/keyring/.pass $(ROOT)/keyring/keycommands
	@$(GPG) --passphrase-file $(ROOT)/keyring/.pass --batch --generate-key $(ROOT)/keyring/keycommands