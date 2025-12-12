function setenv --description 'Set and export environment variable globally'
    if test (count $argv) -lt 2
        echo "Usage: setenv VARIABLE VALUE"
        echo "Example: setenv MY_TERMINAL ghostty"
        return 1
    end
    
    set -gx $argv[1] $argv[2..-1]
    echo "Set $argv[1] = $argv[2..-1]"
end
