#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Test script for bulk-import-students Edge Function
# 
# Usage:
#   1. Set your variables below
#   2. Run: ./supabase/scripts/test_bulk_import.sh
# ─────────────────────────────────────────────────────────────────────────────

# ── Configuration ────────────────────────────────────────────────────────────
SUPABASE_URL="https://zhlrzzhwumcxtstuybdb.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpobHJ6emh3dW1jeHRzdHV5YmRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2NjQxNjksImV4cCI6MjA5MjI0MDE2OX0.hk8O5-WU5iXcHPDGXxLr3bBoKj4A9pcjKO2hWsAbt34"

# ── Admin credentials (must be an existing admin account) ────────────────────
ADMIN_EMAIL="jreyes@devcon.ph"
ADMIN_PASSWORD="Studfy@123"

# ─────────────────────────────────────────────────────────────────────────────

echo "🔐 Logging in as admin..."
LOGIN_RESPONSE=$(curl -s -X POST "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
  -H "apikey: ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"${ADMIN_EMAIL}\", \"password\": \"${ADMIN_PASSWORD}\"}")

ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)

if [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Login failed. Response:"
  echo "$LOGIN_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$LOGIN_RESPONSE"
  exit 1
fi

echo "✅ Logged in successfully"
echo ""

# ── Test 1: Valid batch (3 test students) ────────────────────────────────────
echo "📋 Test 1: Importing 3 test students..."
RESPONSE=$(curl -s -X POST "${SUPABASE_URL}/functions/v1/bulk-import-students" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "students": [
      {
        "name": "Test Student One",
        "email": "test.student.one.studfy@gmail.com",
        "course": "BSIT",
        "yearSection": "2-A",
        "studentNumber": "2024-TEST-001"
      },
      {
        "name": "Test Student Two",
        "email": "test.student.two.studfy@gmail.com",
        "course": "BSIT",
        "yearSection": "2-A",
        "studentNumber": "2024-TEST-002"
      },
      {
        "name": "Test Student Three",
        "email": "test.student.three.studfy@gmail.com",
        "course": "BSCpE",
        "yearSection": "2-B",
        "studentNumber": "2024-TEST-003"
      }
    ]
  }')

echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
echo ""

# ── Test 2: Duplicate detection (same emails again) ─────────────────────────
echo "📋 Test 2: Re-importing same students (should be skipped)..."
RESPONSE2=$(curl -s -X POST "${SUPABASE_URL}/functions/v1/bulk-import-students" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "students": [
      {
        "name": "Test Student One",
        "email": "test.student.one.studfy@gmail.com",
        "course": "BSIT",
        "yearSection": "2-A"
      }
    ]
  }')

echo "$RESPONSE2" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE2"
echo ""

# ── Test 3: Validation errors (missing fields, bad email) ───────────────────
echo "📋 Test 3: Invalid data (should show errors)..."
RESPONSE3=$(curl -s -X POST "${SUPABASE_URL}/functions/v1/bulk-import-students" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "students": [
      {
        "name": "",
        "email": "missing.name@gmail.com",
        "course": "BSIT",
        "yearSection": "2-A"
      },
      {
        "name": "Bad Email",
        "email": "not-an-email",
        "course": "BSIT",
        "yearSection": "2-A"
      },
      {
        "name": "Missing Course",
        "email": "no.course@gmail.com",
        "course": "",
        "yearSection": "2-A"
      }
    ]
  }')

echo "$RESPONSE3" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE3"
echo ""

# ── Cleanup: Delete test students ────────────────────────────────────────────
echo "🧹 Cleaning up test students..."
CLEANUP=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/rpc/execute_sql" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "apikey: ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{}' 2>/dev/null)

echo ""
echo "─────────────────────────────────────────────────────────"
echo "⚠️  To clean up test accounts, run this SQL in Supabase:"
echo ""
echo "  DELETE FROM student_profiles"
echo "    WHERE profile_id IN ("
echo "      SELECT id FROM profiles"
echo "      WHERE email LIKE '%studfy@gmail.com'"
echo "    );"
echo "  DELETE FROM profiles WHERE email LIKE '%studfy@gmail.com';"
echo "  DELETE FROM auth.users WHERE id NOT IN (SELECT id FROM profiles);"
echo "─────────────────────────────────────────────────────────"
echo ""
echo "✅ Tests complete!"
