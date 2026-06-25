import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final client = SupabaseClient(
    'https://zhlrzzhwumcxtstuybdb.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpobHJ6emh3dW1jeHRzdHV5YmRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2NjQxNjksImV4cCI6MjA5MjI0MDE2OX0.hk8O5-WU5iXcHPDGXxLr3bBoKj4A9pcjKO2hWsAbt34',
  );

  print('Querying subject offerings...');
  try {
    final offerings = await client
        .from('subject_offerings')
        .select('id,subject_name,course_code,section,professor_profile_id');
    for (final row in offerings) {
      print('Offering: ${row['subject_name']} (${row['course_code']})');
      print('  Professor ID: ${row['professor_profile_id']}');
      
      final profId = row['professor_profile_id'];
      if (profId != null && profId.toString().isNotEmpty) {
        try {
          final prof = await client.from('profiles').select().eq('id', profId).maybeSingle();
          print('  Profile: $prof');
        } catch (e) {
          print('  Error fetching profile: $e');
        }
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
