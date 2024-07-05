export ROOT:=$(realpath $(dir $(firstword $(MAKEFILE_LIST))))
PIIP?=192.168.1.162
PIUSER?=forud
BUNDLE?=https://ecal.rubi.gd/bundle.zip

PIHOST:=$(PIUSER)@$(PIIP)
PICMD:=ssh $(PIHOST) -o LogLevel=QUIET -t
PIROOT:="/home/$(PIUSER)/ecal"
PISYNC:=rsync -avz --update -e ssh
GPG:=gpg --homedir=$(ROOT)/keyring --no-default-keyring --keyring $(ROOT)/keyring/trust.db --pinentry-mode=loopback 

setup-requirements:
	@$(PICMD) "sh -c 'type gpg'" 
	@$(PICMD) "sh -c 'type rsync'" 
	@$(PICMD) "sh -c 'type python'" 
	@$(PICMD) "sh -c 'type unzip'"
	@$(PICMD) "sh -c 'type curl'"
	@$(PICMD) "sh -c 'type sed'"

setup-root:
	@$(PICMD) mkdir -p $(PIROOT)
	@$(PICMD) mkdir -p $(PIROOT)/keyring

setup-render:
	@$(PISYNC) $(ROOT)/render $(PIHOST):$(PIROOT)/

setup-decoder:
	@$(PISYNC) $(ROOT)/decoder $(PIHOST):$(PIROOT)/

setup-gpg: $(ROOT)/keyring/private.key $(ROOT)/keyring/public.key $(ROOT)/keyring/.pass
	@$(PISYNC) $(ROOT)/keyring/private.key $(PIHOST):$(PIROOT)/keyring
	@$(PISYNC) $(ROOT)/keyring/public.key $(PIHOST):$(PIROOT)/keyring
	@$(PISYNC) $(ROOT)/keyring/.pass $(PIHOST):$(PIROOT)/keyring

define MAINSCRIPT
#!/bin/bash 
set -euo pipefail

cd $(PIROOT)
curl $(BUNDLE) > $(PIROOT)/bundle.zip
unzip -o $(PIROOT)/bundle.zip
gpg --homedir=$(PIROOT)/keyring --no-default-keyring --keyring $(PIROOT)/keyring/trust.db --pinentry-mode=loopback --passphrase-file $(PIROOT)/keyring/.pass --import $(PIROOT)/keyring/private.key
gpg --homedir=$(PIROOT)/keyring --no-default-keyring --keyring $(PIROOT)/keyring/trust.db --pinentry-mode=loopback --passphrase-file $(PIROOT)/keyring/.pass --decrypt $(PIROOT)/black.bmp.enc > black.bmp
gpg --homedir=$(PIROOT)/keyring --no-default-keyring --keyring $(PIROOT)/keyring/trust.db --pinentry-mode=loopback --passphrase-file $(PIROOT)/keyring/.pass --decrypt $(PIROOT)/red.bmp.enc > red.bmp

python $(PIROOT)/render/ecal.py $(PIROOT)/black.bmp $(PIROOT)/red.bmp
sleep 30 
sudo shutdown -h now
endef
export MAINSCRIPT
 
setup-script: 
	echo "$$MAINSCRIPT" > $(ROOT)/setup.sh
	$(PISYNC) $(ROOT)/setup.sh $(PIHOST):$(PIROOT)/setup.sh
	$(PICMD) chmod a+x $(PIROOT)/setup.sh
	$(PICMD) sudo cp $(PIROOT)/setup.sh /usr/local/bin/setup.sh
	rm $(ROOT)/setup.sh


setup: setup-requirements setup-root setup-render setup-decoder setup-gpg setup-script
	
clean-screen: setup
	@$(PICMD) python $(PIROOT)/render/ecal.py --clear x x 

test: setup-decoder
	@$(PICMD) sh $(PIROOT)/decoder/decode.sh

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

$(ROOT)/keyring/public.key:
	@$(GPG) --export --armor $(PIHOST) > $@

$(ROOT)/keyring/private.key:
	$(GPG) --passphrase-file $(ROOT)/keyring/.pass --export-secret-keys --armor $(PIHOST) > $@

priv: $(ROOT)/keyring/private.key

keys: $(ROOT)/keyring/public.key $(ROOT)/keyring/private.key
	@cat $(ROOT)/keyring/public.key 

clean: 
	@read -p "This will delete the GPG setup for the app (if you already did the setup) if you are not sure press CTRL+C, Enter to continue"
	git clean -fX $(ROOT)/keyring

setup-keys: $(ROOT)/keyring/.pass $(ROOT)/keyring/keycommands
	@read -p "This will create a new key, if you aleready did this please stop here, or make sure to call make clean to delete that one first, CTRL+C to cancel" 
	@mkdir -p $(ROOT)/keyring/private-keys-v1.d
	@$(GPG) --passphrase-file $(ROOT)/keyring/.pass --batch --generate-key $(ROOT)/keyring/keycommands

gtest: 
	$(GPG) --passphrase-file $(ROOT)/keyring/.pass --decrypt /home/f0rud/src/github.com/fzerorubigd/ecal-repo/black.bmp > b.bmp
