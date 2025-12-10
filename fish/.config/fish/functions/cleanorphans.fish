function cleanorphans
    set orphans (pacman -Qtdq 2>/dev/null)
    
    if test -n "$orphans"
        set count (count $orphans)
        set_color green
        echo "Found $count orphaned package(s):"
        set_color normal
        
        for pkg in $orphans
            echo "  - $pkg"
        end
        
        echo
        read -P "Remove them? [y/N] " -n 1 confirm
        echo
        
        if string match -qi "y" $confirm
            sudo pacman -Rns $orphans
        else
            set_color yellow
            echo "Cleanup cancelled"
            set_color normal
        end
    else
        set_color blue
        echo "✓ No orphaned packages found"
        set_color normal
    end
end
