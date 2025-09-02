#!/bin/env fish
#
# function envsource
#   for line in (cat $argv | grep -v '^#')
#     set item (string split -m 1 '=' $line)
#     set -gx $item[1] $item[2]
#     echo "Exported key $item[1]"
#   end
# end
function envsource
    if not test -f $argv
        return 1
    end

    for line in (cat $argv)
        # Skip empty lines
        if test -z "$line"
            continue
        end

        # Skip lines starting with "#"
        if string match -rq '^\s*#' "$line"
            continue
        end

        set key (string split -m1 "=" $line)[1]
        set val (string split -m1 "=" $line)[2]

        # Trim quotes and whitespace
        set key (string trim $key)
        set val (string trim -c "'\" " $val)

        if test -n "$key"
            set -gx $key $val
        end
    end
end
