#!/bin/bash

set -e

efi-updatevar -f PK.auth PK
efi-updatevar -f KEK.auth KEK
efi-updatevar -f db.auth db
