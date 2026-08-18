import 'package:flutter_test/flutter_test.dart';
import 'package:prince_academy/core/config/supabase_config.dart';
import 'package:prince_academy/core/helpers/coach_photo_helper.dart';

void main() {
  final base = SupabaseConfig.url.replaceAll(RegExp(r'/+$'), '');

  group('CoachPhotoHelper.thumbnailUrl', () {
    test('rewrites public object URLs to the render endpoint', () {
      final original =
          '$base/storage/v1/object/public/coach-photos/coaches/a.jpg';
      final thumb = CoachPhotoHelper.thumbnailUrl(original);

      expect(thumb, isNotNull);
      expect(thumb, contains('/storage/v1/render/image/public/coach-photos/'));
      expect(thumb, contains('width=256'));
      expect(thumb, contains('height=256'));
      expect(thumb, contains('resize=cover'));
      expect(thumb, isNot(contains('/object/public/')));
    });

    test('builds a public URL from a storage path then transforms it', () {
      final thumb = CoachPhotoHelper.thumbnailUrl('coaches/a.jpg');
      expect(thumb, startsWith('$base/storage/v1/render/image/public/'));
      expect(thumb, contains('coaches/a.jpg'));
    });

    test('leaves local paths unchanged', () {
      expect(CoachPhotoHelper.thumbnailUrl('/tmp/photo.jpg'), '/tmp/photo.jpg');
    });

    test('returns null for empty values', () {
      expect(CoachPhotoHelper.thumbnailUrl(null), isNull);
      expect(CoachPhotoHelper.thumbnailUrl(''), isNull);
    });
  });

  group('CoachPhotoHelper.heroUrl', () {
    test('requests an 800px render of a public object URL', () {
      final original =
          '$base/storage/v1/object/public/coach-photos/coaches/a.jpg';
      final hero = CoachPhotoHelper.heroUrl(original);
      expect(hero, contains('width=800'));
      expect(hero, contains('/render/image/public/'));
    });
  });

  group('CoachPhotoHelper.transformedPublicUrl', () {
    test('returns null for non-storage URLs', () {
      expect(
        CoachPhotoHelper.transformedPublicUrl(
          'https://cdn.example.com/photo.jpg',
          width: 256,
        ),
        isNull,
      );
    });

    test('does not double-wrap an existing render URL', () {
      const render =
          'https://example.supabase.co/storage/v1/render/image/public/coach-photos/a.jpg?width=256';
      expect(
        CoachPhotoHelper.transformedPublicUrl(render, width: 128),
        render,
      );
    });
  });
}
