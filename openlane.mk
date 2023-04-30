# SPDX-FileCopyrightText: 2020 Efabless Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

MAKEFLAGS+=--warn-undefined-variables

export OPENLANE_RUN_TAG = $(shell date '+%y_%m_%d_%H_%M')
OPENLANE_TAG ?= 2022.10.20
OPENLANE_IMAGE_NAME ?= efabless/openlane:$(OPENLANE_TAG)
designs = $(shell cd $(PROJECT_ROOT)/openlane && find * -maxdepth 0 -type d)
current_design = null

openlane_cmd = \
	"flow.tcl \
	-design $(PROJECT_ROOT)/openlane/$* \
	-save_path $(PROJECT_ROOT) \
	-save \
	-tag $(OPENLANE_RUN_TAG) \
	-overwrite \
	-ignore_mismatches"
openlane_cmd_interactive = "flow.tcl -it -file $$(realpath $(PROJECT_ROOT)/openlane/$*/interactive.tcl)"

docker_mounts = \
	-v $(PROJECT_ROOT):$(PROJECT_ROOT) \
	-v $(PDK_ROOT):/pdk \
	-w $(PROJECT_ROOT) \
	-v $(OPENLANE_ROOT):/openlane

docker_env = \
	-e PDK_ROOT=/pdk \
	-e PDK=$(PDK) \
	-e MISMATCHES_OK=1 \
	-e OPENLANE_RUN_TAG=$(OPENLANE_RUN_TAG)

docker_startup_mode = $(shell test -t 0 && echo "-it" || echo "--rm" )
docker_run = \
	docker run $(docker_startup_mode) \
	$(docker_mounts) \
	$(docker_env) \
	-u $(shell id -u $(USER)):$(shell id -g $(USER))

list:
	@echo $(designs)

.PHONY: $(designs)
$(designs) : export current_design=$@
$(designs) : % : $(PROJECT_ROOT)/openlane/%/config.json
ifneq (,$(wildcard $(PROJECT_ROOT)/openlane/$(current_design)/interactive.tcl))
	$(docker_run) \
		$(OPENLANE_IMAGE_NAME) sh -c $(openlane_cmd_interactive)
else
	# $(current_design)
	mkdir -p $(PROJECT_ROOT)/openlane/$*/runs/$(OPENLANE_RUN_TAG)
	rm -rf $(PROJECT_ROOT)/openlane/$*/runs/$*
	ln -s $(PROJECT_ROOT)/openlane/$*/runs/$(OPENLANE_RUN_TAG) $(PROJECT_ROOT)/openlane/$*/runs/$*
	$(docker_run) \
		$(OPENLANE_IMAGE_NAME) sh -c $(openlane_cmd)
endif
	@mkdir -p $(PROJECT_ROOT)/signoff/$*/
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/OPENLANE_VERSION $(PROJECT_ROOT)/signoff/$*/
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/PDK_SOURCES $(PROJECT_ROOT)/signoff/$*/
	@cp $(PROJECT_ROOT)/openlane/$*/runs/$*/reports/*.csv $(PROJECT_ROOT)/signoff/$*/

