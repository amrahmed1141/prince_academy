import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/features/admin/data/models/branch_model.dart';

class BranchRepository {
  final SupabaseClient supabase;

  BranchRepository(this.supabase);

  Future<List<Branch>> getAllBranches() async {
    try {
      final response = await supabase.from('branches').select().order('name');
      return (response as List)
          .map((json) => Branch.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } on PostgrestException catch (e) {
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
      return Branch.fromJson(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      throw Exception('Failed to update branch: ${e.message}');
    }
  }

  Future<void> deleteBranch(String branchId) async {
    try {
      await supabase.from('branches').delete().eq('id', branchId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete branch: ${e.message}');
    }
  }
}
