import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/widgets/app_search_bar.dart';
import 'package:prince_academy/core/widgets/scroll_away_search_header.dart';
import 'package:prince_academy/features/admin/data/admin_search_index.dart';
import 'package:prince_academy/features/admin/data/repositories/finance_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/finance_bloc.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_transaction_tile.dart';
import 'package:prince_academy/features/admin/presentation/widgets/reject_payment_dialog.dart';

class AllFinanceTransactionsPage extends StatefulWidget {
  const AllFinanceTransactionsPage({super.key});

  @override
  State<AllFinanceTransactionsPage> createState() =>
      _AllFinanceTransactionsPageState();
}

class _AllFinanceTransactionsPageState
    extends State<AllFinanceTransactionsPage> {
  final _searchController = TextEditingController();
  FinanceTxFilter _filter = FinanceTxFilter.confirmed;
  String _query = '';
  String? _expandedBookingId;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<FinanceTransaction> _filterList(List<FinanceTransaction> source) {
    return source.where((tx) {
      final statusOk = switch (_filter) {
        FinanceTxFilter.all => true,
        FinanceTxFilter.confirmed => tx.isConfirmed,
        FinanceTxFilter.pending => tx.isPending,
        FinanceTxFilter.autoCanceled => tx.isAutoCanceled,
      };
      return statusOk && tx.matchesSearch(_query);
    }).toList(growable: false);
  }

  Future<void> _reject(FinanceTransaction tx) async {
    final reason = await RejectPaymentDialog.show(context);
    if (reason == null || !mounted) return;
    context.read<FinanceCubit>().rejectPayment(tx.bookingId, reason);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      body: BlocConsumer<FinanceCubit, FinanceState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage ||
            previous.successMessage != current.successMessage,
        listener: (context, state) {
          final error = state.errorMessage;
          final success = state.successMessage;
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: AppColors.error),
            );
            context.read<FinanceCubit>().clearMessages();
          } else if (success != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<FinanceCubit>().clearMessages();
            setState(() => _expandedBookingId = null);
          }
        },
        buildWhen: (previous, current) =>
            previous.data != current.data ||
            previous.isInitialLoading != current.isInitialLoading ||
            previous.busyBookingIds != current.busyBookingIds,
        builder: (context, state) {
          if (state.isInitialLoading && state.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = state.data;
          if (data == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () => context.read<FinanceCubit>().load(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColorConstants.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Retry'),
              ),
            );
          }

          final items = _filterList(data.transactions);

          return NestedScrollView(
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, _) => [
              ScrollAwaySearchHeader(
                backgroundColor: const Color(0xFFF9F6F2),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: AppColors.textPrimary,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                title: const Text(
                  'All Transactions',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                searchBar: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: AppSearchBar(
                    controller: _searchController,
                    hintText: 'Search member, coach, or time',
                    hintPhrases: AdminSearchHints.transactions,
                    variant: AppSearchBarVariant.elevated,
                    padding: EdgeInsets.zero,
                    onChanged: (value) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 220), () {
                        if (!mounted) return;
                        setState(() => _query = value);
                      });
                    },
                    onClear: () => setState(() => _query = ''),
                  ),
                ),
              ),
            ],
            body: Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FinanceTxFilterChips(
                    value: _filter,
                    showAll: false,
                    onChanged: (filter) {
                      setState(() {
                        _filter = filter;
                        _expandedBookingId = null;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    color: EColorConstants.primaryColor,
                    onRefresh: () => context.read<FinanceCubit>().refresh(),
                    child: items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Text(
                                  'No transactions found',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final tx = items[index];
                              return FinanceTransactionTile(
                                transaction: tx,
                                expanded: _expandedBookingId == tx.bookingId,
                                isBusy:
                                    state.busyBookingIds.contains(tx.bookingId),
                                onTap: () {
                                  if (!tx.isPending) return;
                                  setState(() {
                                    _expandedBookingId =
                                        _expandedBookingId == tx.bookingId
                                            ? null
                                            : tx.bookingId;
                                  });
                                },
                                onConfirm: () => context
                                    .read<FinanceCubit>()
                                    .verifyPayment(tx.bookingId),
                                onCancel: () => _reject(tx),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
