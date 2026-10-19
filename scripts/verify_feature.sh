#!/bin/bash

# Flutter Feature Quality Gate Script
# Use this script locally or in CI to ensure vibe-coded code satisfies all quality gates.

set -e

echo "=========================================="
echo "🛡️  Running Flutter Quality Gate Verification"
echo "=========================================="

echo ""
echo "Step 1: Checking Dart Code Formatting..."
dart format --output=none --set-exit-if-changed . || {
    echo "❌ Format check failed! Run 'dart format .' to automatically format files."
    exit 1
}
echo "✅ Code formatting is clean."

echo ""
echo "Step 2: Running Static Analysis (flutter analyze)..."
flutter analyze --fatal-infos || {
    echo "❌ Static analysis failed! Resolve all warnings and lints."
    exit 1
}
echo "✅ 0 errors and 0 warnings found."

echo ""
echo "Step 3: Running Automated Test Suites..."
flutter test --coverage || {
    echo "❌ Test suite failed! Check test failures above."
    exit 1
}
echo "✅ All tests passed successfully."

echo ""
echo "=========================================="
echo "🎉 Quality Gate Passed! Feature is Production Ready."
echo "=========================================="
