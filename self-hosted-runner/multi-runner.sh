# Register runners for all repositories simultaneously
register_runners_parallel() {
    echo "🚀 Starting parallel runner registration for ${#REPO_ARRAY[@]} repositories..."
    local pids=()
  
    for repo in "${REPO_ARRAY[@]}"; do
        echo "🔄 Launching registration for $repo..."
        register_single_runner "$repo" &
        pids+=($!)
    done
  
    # Wait for all registrations to complete
    for pid in "${pids[@]}"; do
        if wait "$pid"; then
            echo "✅ Registration process $pid completed successfully"
        else
            echo "❌ Registration process $pid failed"
        fi
    done
}

# Maintain runner state for proper cleanup
track_runner_state() {
    local repo="$1"
    local runner_name="$2" 
    local pid="$3"
    local workdir="$4"
  
    # Store runner information for shutdown handling
    echo "$repo|$runner_name|$pid|$workdir|$(date +%s)" >> "$ACTIVE_RUNNERS_FILE"
}

# Enhanced cleanup with parallel de-registration
cleanup() {
    echo "🧹 Starting graceful cleanup and de-registration process..."
  
    # Step 1: Stop all runner processes
    stop_all_runner_processes
  
    # Step 2: De-register all runners in parallel
    local runners_to_deregister=()
    # ... collect runner information ...
  
    # Launch parallel de-registration
    for runner_info in "${runners_to_deregister[@]}"; do
        deregister_runner_async "$repo" "$runner_name" "$workdir" &
        pids+=($!)
    done
  
    # Wait for completion with timeout
    wait_for_parallel_completion "${pids[@]}"
}
