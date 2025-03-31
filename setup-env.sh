#!/bin/bash

ROOT_ENV=".env.local"

API_ENV="subclip-api/.env.dist"
API_LOCAL_ENV="subclip-api/.env"

SE_ENV="subclip-sound-extractor/.env"
SE_LOCAL_ENV="subclip-sound-extractor/.env.local"

SG_ENV="subclip-subtitle-generator/.env"
SG_LOCAL_ENV="subclip-subtitle-generator/.env.local"

SM_ENV="subclip-subtitle-merger/.env"
SM_LOCAL_ENV="subclip-subtitle-merger/.env.local"

# Check if source files exist
if [ ! -f "$API_ENV" ] || [ ! -f "$SE_ENV" ] || [ ! -f "$SG_ENV" ] || [ ! -f "$SM_ENV" ]; then
    echo "Source environment files not found"
    exit 1
fi

rm -r "$API_LOCAL_ENV" "$SE_LOCAL_ENV" "$SG_LOCAL_ENV" "$SM_LOCAL_ENV" 2> /dev/null

# Create local copies
cp "$API_ENV" "$API_LOCAL_ENV"
cp "$SE_ENV" "$SE_LOCAL_ENV"
cp "$SG_ENV" "$SG_LOCAL_ENV"
cp "$SM_ENV" "$SM_LOCAL_ENV"

# Improved get_env_var function that handles quoted values
get_env_var() {
    local file=$1
    local var_name=$2
    local value=$(grep -E "^${var_name}=" "$file" | tail -n 1 | cut -d'=' -f2-)
    # Remove surrounding quotes if they exist
    value="${value#\"}"
    value="${value%\"}"
    echo "$value"
}

# Set appropriate sed command based on OS
if [[ "$(uname)" == "Darwin" ]]; then
    SED_I=("sed" "-i" "")  # macOS - using array to handle arguments properly
else
    SED_I=("sed" "-i")     # Linux
fi

# Improved replace_env_vars function
replace_env_vars() {
    local source_file=$1
    local target_file=$2
    local max_iterations=5  # Increased iterations for complex nested variables
    
    for ((i=0; i<max_iterations; i++)); do
        local replaced=false
        
        # Read file line by line
        while IFS= read -r line || [ -n "$line" ]; do
            if [[ "$line" =~ .*\$\{([A-Za-z_][A-Za-z0-9_]*)\}.* ]]; then
                local var_name="${BASH_REMATCH[1]}"
                # First try ROOT_ENV, then source_file
                local replacement_value=$(get_env_var "$ROOT_ENV" "$var_name")
                if [ -z "$replacement_value" ]; then
                    replacement_value=$(get_env_var "$source_file" "$var_name")
                fi
                
                if [ -n "$replacement_value" ]; then
                    # Escape special characters in the replacement value
                    replacement_value=$(echo "$replacement_value" | sed 's/[\/&]/\\&/g')
                    "${SED_I[@]}" "s/\${$var_name}/$replacement_value/g" "$target_file"
                    replaced=true
                fi
            fi
        done < "$target_file"
        
        # Break if no replacements were made in this iteration
        if [ "$replaced" = false ]; then
            break
        fi
    done
}

# Perform replacements
replace_env_vars "$API_ENV" "$API_LOCAL_ENV"
replace_env_vars "$SE_ENV" "$SE_LOCAL_ENV"
replace_env_vars "$SG_ENV" "$SG_LOCAL_ENV"
replace_env_vars "$SM_ENV" "$SM_LOCAL_ENV"
