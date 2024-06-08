export ROOT:=$(realpath $(dir $(firstword $(MAKEFILE_LIST))))
PIIP?=192.168.1.162
PIUSER?=forud
BUNDLE?=http://192.168.1.211:8000/bundle.zip

PIHOST:=$(PIUSER)@$(PIIP)
PICMD:=ssh $(PIHOST) -o LogLevel=QUIET -t
PIROOT:="/home/$(PIUSER)/ecal"
PISYNC:=rsync -avz --update -e ssh

setup-root:
	@$(PICMD) mkdir -p $(PIROOT)

setup-render:
	@$(PISYNC) $(ROOT)/render $(PIHOST):$(PIROOT)/

setup: setup-root setup-render
	
clean-screen: setup
	@$(PICMD) python $(PIROOT)/render/ecal.py --clear x x 