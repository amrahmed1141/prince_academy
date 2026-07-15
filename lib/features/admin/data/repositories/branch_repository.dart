import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/core/cache/local_cache_store.dart';
import 'package:prince_academy/core/cache/ttl_cache.dart';
import 'package:prince_academy/features/admin/data/models/branch_model.dart';

class BranchRepository {
  BranchRepository(this.supabase, {LocalCacheStore? cache})
      : _cache = cache ?? LocalCacheStore.instance {
    _hydrateFromDisk();
  }

  final SupabaseClient supabase;
  final LocalCacheStore _cache;
  final TtlCache<List<Branch>> _memoryCache = TtlCache(
    ttl: const Duration(minutes: 10),
  );

  List<Branch>? get cachedBranches => _memoryCache.value;

  void _hydrateFromDisk() {
    if (_memoryCache.value != null) return;
    final list = _cache.getList(LocalCacheStore.branchesKey());
    if (list == null) return;
    try {
      final branches = list
          .map((e) => Branch.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _memoryCache.set(branches);
    } catch (_) {}
  }

  Future<void> _persist(List<Branch> branches) async {
    await _cache.putJson(
      LocalCacheStore.branchesKey(),
      branches.map((b) => b.toJson()).toList(),
    );
  }

  Future<List<Branch>> getAllBranches({bool force = false}) async {
    _hydrateFromDisk();
    if (!force) {
      final cached = _memoryCache.value;
      if (cached != null) return cached;
    }

    try {
      final response = await supabase.from('branches').select().order('name');
      final branches = (response as List)
          .map((json) => Branch.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
      _memoryCache.set(branches);
      unawaited(_persist(branches));
      return branches;
    } on PostgrestException catch (e) {
      final stale = _memoryCache.value;
      if (stale != null) return stale;
      throw Exception('Failed to load branches: ${e.message}');
    }
  }

  Future<Branch> addBranch({
    required String name,
    String? address,
    String? phone,
  }) async {
    try {
      final response = await supabase
          .from('branches')
          .insert({
            'name': name.trim(),
            'address': address?.trim().isEmpty == true ? null : address?.trim(),
            'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
          })
          .select()
          .single();
      _memoryCache.invalidate();
      return Branch.fromJson(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('Failed to add branch: ${e.message}');
    }
  }

  Future<Branch> updateBranch({
    required String id,
    required String name,
    String? address,
    String? phone,
  }) async {
    try {
      final response = await supabase
          .from('branches')
          .update({
            'name': name.trim(),
            'address': address?.trim().isEmpty == true ? null : address?.trim(),
            'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
          })
          .eq('id', id)
          .select()
          .single();
      _memoryCache.invalidate();
      return Branch.fromJson(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('Failed to update branch: ${e.message}');
    }
  }

  Future<void> deleteBranch(String branchId) async {
    try {
      await supabase.from('branches').delete().eq('id', branchId);
      _memoryCache.invalidate();
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete branch: ${e.message}');
    }
  }
}
