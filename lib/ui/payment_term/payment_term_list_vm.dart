import 'dart:async';
import 'package:invoiceninja_flutter/data/models/payment_term_model.dart';
import 'package:invoiceninja_flutter/ui/app/entities/entity_actions_dialog.dart';
import 'package:invoiceninja_flutter/ui/app/tables/entity_list.dart';
import 'package:invoiceninja_flutter/ui/payment_term/payment_term_list_item.dart';
import 'package:redux/redux.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:invoiceninja_flutter/redux/ui/list_ui_state.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:invoiceninja_flutter/redux/payment_term/payment_term_selectors.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/payment_term/payment_term_actions.dart';

class PaymentTermListBuilder extends StatelessWidget {
  const PaymentTermListBuilder({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, PaymentTermListVM>(
      converter: PaymentTermListVM.fromStore,
      builder: (context, viewModel) {
        return EntityList(
            isLoaded: viewModel.isLoaded,
            entityType: EntityType.paymentTerm,
            state: viewModel.state,
            entityList: viewModel.paymentTermList,
            onEntityTap: viewModel.onPaymentTermTap,
            tableColumns: viewModel.tableColumns,
            onRefreshed: viewModel.onRefreshed,
            onClearEntityFilterPressed: viewModel.onClearEntityFilterPressed,
            onViewEntityFilterPressed: viewModel.onViewEntityFilterPressed,
            onSortColumn: viewModel.onSortColumn,
            itemBuilder: (BuildContext context, index) {
              final state = viewModel.state;
              final paymentTermId = viewModel.paymentTermList[index];
              final paymentTerm = viewModel.paymentTermMap[paymentTermId];
              final listState = state.getListState(EntityType.paymentTerm);
              final isInMultiselect = listState.isInMultiselect();

              return PaymentTermListItem(
                user: viewModel.state.user,
                filter: viewModel.filter,
                paymentTerm: paymentTerm,
                onEntityAction: (EntityAction action) {
                  if (action == EntityAction.more) {
                    showEntityActionsDialog(
                      entities: [paymentTerm],
                      context: context,
                    );
                  } else {
                    handlePaymentTermAction(context, [paymentTerm], action);
                  }
                },
                onTap: () => viewModel.onPaymentTermTap(context, paymentTerm),
                onLongPress: () async {
                  final longPressIsSelection =
                      state.prefState.longPressSelectionIsDefault ?? true;
                  if (longPressIsSelection && !isInMultiselect) {
                    handlePaymentTermAction(
                        context, [paymentTerm], EntityAction.toggleMultiselect);
                  } else {
                    showEntityActionsDialog(
                      entities: [paymentTerm],
                      context: context,
                    );
                  }
                },
                isChecked:
                    isInMultiselect && listState.isSelected(paymentTerm.id),
              );
            });
      },
    );
  }
}

class PaymentTermListVM {
  PaymentTermListVM({
    @required this.state,
    @required this.userCompany,
    @required this.paymentTermList,
    @required this.paymentTermMap,
    @required this.filter,
    @required this.isLoading,
    @required this.isLoaded,
    @required this.onPaymentTermTap,
    @required this.listState,
    @required this.onRefreshed,
    @required this.onEntityAction,
    @required this.onClearEntityFilterPressed,
    @required this.onViewEntityFilterPressed,
    @required this.onSortColumn,
    this.tableColumns,
  });

  static PaymentTermListVM fromStore(Store<AppState> store) {
    Future<Null> _handleRefresh(BuildContext context) {
      if (store.state.isLoading) {
        return Future<Null>(null);
      }
      final completer = snackBarCompleter<Null>(
          context, AppLocalization.of(context).refreshComplete);
      store.dispatch(LoadPaymentTerms(completer: completer, force: true));
      return completer.future;
    }

    final state = store.state;

    return PaymentTermListVM(
      state: state,
      userCompany: state.userCompany,
      listState: state.paymentTermListState,
      paymentTermList: memoizedFilteredPaymentTermList(
          state.paymentTermState.map,
          state.paymentTermState.list,
          state.paymentTermListState),
      paymentTermMap: state.paymentTermState.map,
      isLoading: state.isLoading,
      isLoaded: state.paymentTermState.isLoaded,
      filter: state.paymentTermUIState.listUIState.filter,
      onClearEntityFilterPressed: () =>
          store.dispatch(FilterPaymentTermsByEntity()),
      onViewEntityFilterPressed: (BuildContext context) => viewEntityById(
          context: context,
          entityId: state.paymentTermListState.filterEntityId,
          entityType: state.paymentTermListState.filterEntityType),
      onPaymentTermTap: (context, paymentTerm) {
        if (store.state.paymentTermListState.isInMultiselect()) {
          handlePaymentTermAction(
              context, [paymentTerm], EntityAction.toggleMultiselect);
        } else {
          viewEntity(context: context, entity: paymentTerm);
        }
      },
      onEntityAction: (BuildContext context, List<BaseEntity> paymentTerms,
              EntityAction action) =>
          handlePaymentTermAction(context, paymentTerms, action),
      onRefreshed: (context) => _handleRefresh(context),
      onSortColumn: (field) => store.dispatch(SortPaymentTerms(field)),
    );
  }

  final AppState state;
  final UserCompanyEntity userCompany;
  final List<String> paymentTermList;
  final BuiltMap<String, PaymentTermEntity> paymentTermMap;
  final ListUIState listState;
  final String filter;
  final bool isLoading;
  final bool isLoaded;
  final Function(BuildContext, BaseEntity) onPaymentTermTap;
  final Function(BuildContext) onRefreshed;
  final Function(BuildContext, List<BaseEntity>, EntityAction) onEntityAction;
  final Function onClearEntityFilterPressed;
  final Function(BuildContext) onViewEntityFilterPressed;
  final List<String> tableColumns;
  final Function(String) onSortColumn;
}
