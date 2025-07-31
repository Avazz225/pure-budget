import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/helper/free_restrictions.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/widgets_shared/background_painter.dart';
import 'package:provider/provider.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:flutter/foundation.dart';


class InAppPurchaseScreen extends StatefulWidget {
  const InAppPurchaseScreen({super.key});

  @override
  InAppPurchaseScreenState createState() => InAppPurchaseScreenState();
}

class InAppPurchaseScreenState extends State<InAppPurchaseScreen> {
  final String productId = proVersionProductId;
  final _doDBOnly = false;
  final _logger = Logger();
  bool _isPro = false;
  bool _loading = true;
  bool _isInitialized = false;
  bool _purchasePending = false;
  bool _purchaseFailed = false;
  StreamSubscription<List<PurchaseDetails>>? _purchaseStreamSubscription;
  ProductDetails _productDetails = ProductDetails(id: "-1", title: "", description: "", price: "0", rawPrice: 0, currencyCode: "€");

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    if (!_isInitialized) {
      final budgetState = Provider.of<BudgetState>(context, listen: false);
      await initializePurchase(budgetState);
      _isInitialized = true;
    }
  }

  
  Future<void> _initializePurchaseListener(BudgetState budgetState) async {
    if (_purchaseStreamSubscription == null) {
      _purchaseStreamSubscription = InAppPurchase.instance.purchaseStream.listen(
        (purchases) async {
          for (final purchase in purchases) {
            if (purchase.productID == productId) {
              if (purchase.status == PurchaseStatus.purchased ||
                  purchase.status == PurchaseStatus.restored) {
                await budgetState.updateIsPro(true);
                setState(() {
                  _isPro = true;
                  _loading = false;
                });
              } else if (purchase.status == PurchaseStatus.pending) {
                _onHandlePending();
              }
            }
          }
        },
        onError: (error) {
          _logger.error("Error in purchase stream: $error", tag: "purchase");
        },
      );
      setState(() {
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _restorePurchases(BudgetState budgetState) async {
    try {
      if (kDebugMode && _doDBOnly) {
        _logger.debug("Debug mode! Setting pro to false", tag: "purchase");
        await budgetState.updateIsPro(false);
        setState(() {
          _isPro = false;
          _loading = false;
        });
      } else {
        await _initializePurchaseListener(budgetState);
        await InAppPurchase.instance.restorePurchases();
      }
    } catch (e) {
      _logger.error("Error restoring purchases: $e", tag: "purchase");
    }
  }

  @override
  void dispose() {
    _purchaseStreamSubscription?.cancel();
    _purchaseStreamSubscription = null;
    super.dispose();
  }

  Future<void> initializePurchase(BudgetState budgetState) async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      setState(() {
        _loading = false;
      });
      return;
    }
    
    await _restorePurchases(budgetState);
  }

  Future<void> _buyProduct(BudgetState budgetState) async {
    if (kDebugMode & _doDBOnly) {
      _logger.debug("Debug mode! Setting pro to true", tag: "purchase");
      await budgetState.updateIsPro(true);
      setState(() {
        _isPro = true;
      });
    } else {
      final purchaseParam = PurchaseParam(productDetails: _productDetails);
      final bool requestSent = await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);

      if (!requestSent) {
        _logger.error("Failed to initiate purchase request.", tag: "purchase");
      } else {
        _setupPurchaseStream(budgetState);
      }
    }
  }

  void _setupPurchaseStream(BudgetState budgetState) {
    InAppPurchase.instance.purchaseStream.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        for (var purchaseDetails in purchaseDetailsList) {
          switch (purchaseDetails.status) {
            case PurchaseStatus.purchased:
              _handlePurchase(purchaseDetails, budgetState);
              break;
            case PurchaseStatus.error:
              _onPurchaseFailed();
              break;
            case PurchaseStatus.pending:
              _onHandlePending();
              break;
            case PurchaseStatus.restored:
              _handlePurchase(purchaseDetails, budgetState);
              break;
            case PurchaseStatus.canceled:
              break;
          }
        }
      },
      onDone: () => _logger.info("Purchase stream closed.", tag: "purchase"),
      onError: (error) => _logger.error("Purchase stream error: $error", tag: "purchase"),
    );
  }

  void _onHandlePending() {
    _logger.debug("Purchase pending...", tag: "purchase");
    setState(() {
      _purchasePending = true;
      _loading = false;
    });
  }

  void _handlePurchase(PurchaseDetails purchaseDetails, BudgetState budgetState) async {
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      await budgetState.updateIsPro(true);
      setState(() {
        _isPro = true;
      });
      InAppPurchase.instance.completePurchase(purchaseDetails);
    }
  }

  void _onPurchaseFailed() {
    _logger.warning("Purchase failed or was cancelled.", tag: "purchase");
    
    _purchaseFailed = true;
  }

  Future<void> _loadProducts() async {
    final productDetailsResponse = await InAppPurchase.instance.queryProductDetails({productId});
    if (productDetailsResponse.error == null && productDetailsResponse.productDetails.isNotEmpty) {
      setState(() {
        _productDetails = productDetailsResponse.productDetails.first;
      });
    }
  }

  Widget buildPurchaseUI(BudgetState budgetState) {
    if (!_isPro) {
      if (!_purchasePending) {
        if (_purchaseFailed) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(I18n.translate("purchaseFailed")),
              ElevatedButton(
                onPressed: () => _buyProduct(budgetState),
                style: btnNegativeStyle,
                child: Text(
                  I18n.translate("upgradeNow", placeholders: {"price": _productDetails.price}),
                  textAlign: TextAlign.center
                ),
              ),
            ],
          );
        } else {
          return ElevatedButton(
            onPressed: () => _buyProduct(budgetState),
            style: btnPositiveStyle,
            child: Text(
              I18n.translate("upgradeNow", placeholders: {"price": _productDetails.price}),
              textAlign: TextAlign.center
            ),
          );
        }
      } else {
        return ElevatedButton(
          onPressed: null,
          style: btnPositiveStyle,
          child: Text(
            I18n.translate("purchasePending"),
            textAlign: TextAlign.center
          ),
        );
      }
    } else {
      return ElevatedButton(
        onPressed: null,
        style: btnPositiveStyle,
        child: Text(
          I18n.translate("justPurchased"),
          textAlign: TextAlign.center
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
      final budgetState = Provider.of<BudgetState>(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(I18n.translate("inappPurchase"))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(I18n.translate("inappPurchase"))),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundPainter(isDarkMode: Theme.of(context).brightness == Brightness.dark, context: context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  I18n.translate(_isPro ? 'alreadyPurchased' : 'upgradeToUnlock'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 20),
                Text(
                  I18n.translate("benefits"),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  I18n.translate("benefitList", placeholders: {"maxPro": "$maxProRanges", "maxFree": "$maxFreeRanges"}),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                buildPurchaseUI(budgetState),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isPro ? null : () => _restorePurchases(budgetState),
                  style: btnNeutralStyle,
                  child: Text(I18n.translate("restorePurchase")),
                ),
              ],
            ),
          ),
        ]
      )
    );
  }
}