#!/bin/env bash


_CurrTemp=$(curl -s "https://wttr.in/%D8%B9%D9%86%D9%8A%D8%B2%D8%A9?format=j1" | jq -r '.current_condition[].temp_C')
_FeelTemp=$(curl -s "https://wttr.in/%D8%B9%D9%86%D9%8A%D8%B2%D8%A9?format=j1" | jq -r '.current_condition[].FeelsLikeC')


echo "󰔏$_CurrTemp($_FeelTemp)"
