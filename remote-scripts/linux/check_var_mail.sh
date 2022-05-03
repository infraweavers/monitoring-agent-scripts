#!/bin/bash

#Exit states
readonly success=0
readonly warning=1
readonly critical=2
readonly unknown=3

countVarMailFiles=$(ls -1 /var/mail/ | wc -l)
[[ $countVarMailFiles -eq 0 ]] \
	&& (echo "OK - /var/mail empty"; exit $success) \
	|| (echo "CRITICAL - /var/mail has entries" ; exit $critical)

