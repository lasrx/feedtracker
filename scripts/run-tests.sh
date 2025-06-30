#!/bin/bash

# Pre-commit test runner for FeedTracker
# Runs unit tests and ensures they pass before allowing commits

set -e  # Exit on any error

echo "🧪 Running FeedTracker unit tests..."

# Change to project directory
cd "$(dirname "$0")/.."

# Check if Xcode is available
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: xcodebuild not found. Xcode is required to run tests."
    exit 1
fi

# Clean previous test results
echo "🧹 Cleaning previous test results..."
rm -rf TestResults/

# Run tests with verbose output
echo "🏃‍♂️ Running unit tests..."
xcodebuild test \
    -scheme FeedTracker \
    -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
    -resultBundlePath TestResults \
    -quiet \
    | grep -E "(Test Suite|Test Case.*started|Test Case.*passed|Test Case.*failed|FAILURE|SUCCESS|Testing failed|Testing succeeded)" \
    || true

# Check test results
if xcodebuild test \
    -scheme FeedTracker \
    -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
    -quiet &> /dev/null; then
    echo "✅ All tests passed! Commit can proceed."
    
    # Count and report test results
    if [ -d "TestResults" ]; then
        echo "📊 Test Summary:"
        # Extract test counts from results if available
        find TestResults -name "*.xcresult" -exec xcrun xcresulttool get --format json --path {} \; 2>/dev/null | \
        jq -r '.actions[0].actionResult.testsRef.id.testSummaries.testResults | length' 2>/dev/null | \
        head -1 | while read count; do
            if [ -n "$count" ] && [ "$count" -gt 0 ]; then
                echo "   📈 $count test cases executed"
            fi
        done || echo "   📈 Test execution completed"
    fi
    
    exit 0
else
    echo "❌ Tests failed! Commit blocked."
    echo ""
    echo "🔍 To see detailed test output, run:"
    echo "   xcodebuild test -scheme FeedTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'"
    echo ""
    echo "🔧 Common issues and fixes:"
    echo "   • Check for syntax errors in test files"
    echo "   • Ensure all test dependencies are properly imported"
    echo "   • Verify mock objects implement required protocols"
    echo "   • Check that test data matches expected formats"
    echo ""
    exit 1
fi