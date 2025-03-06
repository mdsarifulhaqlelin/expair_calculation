import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 5,
        ),
      ),
      home: MyHomePage(title: 'Expair Calculation'),
    );
  }
}

class Product {
  // ignore: non_constant_identifier_names
  final String Id;
  // ignore: non_constant_identifier_names
  final String Product_name;
  // ignore: non_constant_identifier_names
  final double Product_Trade_Price;
  // ignore: non_constant_identifier_names
  final double Vat_price;
  // ignore: non_constant_identifier_names
  final double Product_total_Price;
  // ignore: non_constant_identifier_names
  final double Product_PerPcs_Price;
  // ignore: non_constant_identifier_names
  final int Box_Quantity;

  Product({
    // ignore: non_constant_identifier_names
    required this.Id,
    // ignore: non_constant_identifier_names
    required this.Product_name,
    // ignore: non_constant_identifier_names
    required this.Product_Trade_Price,
    // ignore: non_constant_identifier_names
    required this.Vat_price,
    // ignore: non_constant_identifier_names
    required this.Product_total_Price,
    // ignore: non_constant_identifier_names
    required this.Product_PerPcs_Price,
    // ignore: non_constant_identifier_names
    required this.Box_Quantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      Id: json['Id'],
      Product_name: json['Product_name'],
      Product_Trade_Price: json['Product_Trade_Price'],
      Vat_price: json['Vat_price'],
      Product_total_Price: json['Product_total_Price'],
      Product_PerPcs_Price: json['Product_PerPcs_Price'],
      Box_Quantity: json['Box_Quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Id': Id,
      'Product_name': Product_name,
      'Product_Trade_Price': Product_Trade_Price,
      'Vat_price': Vat_price,
      'Product_total_Price': Product_total_Price,
      'Product_PerPcs_Price': Product_PerPcs_Price,
      'Box_Quantity': Box_Quantity,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.Id == Id;
  }

  @override
  int get hashCode => Id.hashCode;
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String, int> productQuantities = {};
  final Map<String, TextEditingController> _quantityControllers = {};
  double get totalAmount {
    double sum = 0.0;
    for (var product in selectedProducts) {
      sum += product.Product_PerPcs_Price *
          (productQuantities[product.Id] ?? 1);
    }
    return sum;
  }

  List<Product> allProducts = [];
  List<Product> selectedProducts = [];
  SharedPreferences? prefs;
  TextEditingController searchController = TextEditingController();
  List<Product> filteredProducts = [];

  // Removed unused _filterProducts method

  void _initializeDefaultProducts() async {
    if (allProducts.isEmpty) {
      allProducts = [
        Product(
          Id: 'NPA51A',
          Product_name: 'Anuva 50 mg',
          Product_Trade_Price: 300.6,
          Vat_price: 52.3,
          Product_total_Price: 352.9,
          Product_PerPcs_Price: 7.058,
          Box_Quantity: 50,
        ),
        Product(
          Id: 'NSA17A',
          Product_name: 'Azyth 500mg',
          Product_Trade_Price: 374.44,
          Vat_price: 65.1522,
          Product_total_Price: 439.59,
          Product_PerPcs_Price: 48.8433333,
          Box_Quantity: 9,
        ),
      ];
      await _saveProducts();
    }
    setState(() {
      filteredProducts = List.from(selectedProducts);
    });
  }

  Future<void> _initPreferences() async {
    prefs = await SharedPreferences.getInstance();
    _loadProducts();
    _initializeDefaultProducts();
  }

  Future<void> _loadProducts() async {
    if (prefs == null) return;

    final String? allProductsString = prefs!.getString('allProducts');
    final String? selectedProductsString = prefs!.getString('selectedProducts');

    if (allProductsString != null) {
      final List<dynamic> allProductsJson = jsonDecode(allProductsString);
      allProducts =
          allProductsJson.map((json) => Product.fromJson(json)).toList();
    }
    if (selectedProductsString != null) {
      final List<dynamic> selectedProductsJson = jsonDecode(
        selectedProductsString,
      );
      selectedProducts =
          selectedProductsJson.map((json) => Product.fromJson(json)).toList();
    }
    setState(() {
      filteredProducts = List.from(selectedProducts);
    });
  }

  Future<void> _saveProducts() async {
    if (prefs == null) return;

    final String allProductsString = jsonEncode(
      allProducts.map((product) => product.toJson()).toList(),
    );
    final String selectedProductsString = jsonEncode(
      selectedProducts.map((product) => product.toJson()).toList(),
    );

    await prefs!.setString('allProducts', allProductsString);
    await prefs!.setString('selectedProducts', selectedProductsString);
  }

  double get totalAmountPerPiece => selectedProducts.fold(
    0.0,
    (sum, product) =>
        sum + (product.Product_total_Price / product.Box_Quantity),
  );

  Future<Product?> _showNewDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    Product? selectedProduct;
    TextEditingController searchController = TextEditingController();
    List<Product> searchResults = [];

    return await showDialog<Product>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add New Product'),
              content: SingleChildScrollView( // Wrap the content with SingleChildScrollView
                child: SizedBox(
                  width: double.maxFinite,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search Product',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchResults = allProducts
                                  .where((product) =>
                                      product.Product_name
                                          .toLowerCase()
                                          .contains(value.toLowerCase()) &&
                                      !selectedProducts.any(
                                          (selected) => selected.Id == product.Id))
                                  .toList();
                            });
                          },
                        ),
                        SizedBox(height: 10),
                        const Text("All Products:", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(
                          height: 150,
                          width: double.maxFinite,
                          child: ListView.builder(
                            itemCount: allProducts.length,
                            itemBuilder: (context, index) {
                              final product = allProducts[index];
                              return ListTile(
                                title: Text(product.Product_name),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _deleteAllProduct(product.Id);
                                    setState(() {
                                      searchResults = allProducts
                                          .where((p) =>
                                              p.Product_name
                                                  .toLowerCase()
                                                  .contains(searchController.text.toLowerCase()) &&
                                              !selectedProducts.any(
                                                  (selected) => selected.Id == p.Id))
                                          .toList();
                                    });
                                  },
                                ),
                                onTap: () {
                                  setState(() {
                                    selectedProduct = product;
                                    searchController.clear();
                                    searchResults.clear();
                                  });
                                },
                                selected: selectedProduct == product,
                                selectedTileColor: Colors.grey[300],
                              );
                            },
                          ),
                        ),
                        if (searchResults.isNotEmpty)
                          SizedBox(
                            height: 150,
                            width: double.maxFinite,
                            child: ListView.builder(
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final product = searchResults[index];
                                return ListTile(
                                  title: Text(product.Product_name),
                                  onTap: () {
                                    setState(() {
                                      selectedProduct = product;
                                      searchController.clear();
                                      searchResults.clear();
                                    });
                                  },
                                  selected: selectedProduct == product,
                                  selectedTileColor: Colors.grey[300],
                                );
                              },
                            ),
                          ),
                        if (searchResults.isEmpty &&
                            searchController.text.isNotEmpty)
                          const Text("No products found."),
                        if (selectedProduct != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              'Selected: ${selectedProduct!.Product_name}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Add'),
                  onPressed: () {
                    if (selectedProduct != null) {
                      Navigator.of(context).pop(selectedProduct);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteProduct(String productId) {
    setState(() {
      selectedProducts.removeWhere((product) => product.Id == productId);
      filteredProducts = List.from(selectedProducts);
      _saveProducts();
    });
  }

  void _deleteAllProduct(String productId) {
    setState(() {
      allProducts.removeWhere((product) => product.Id == productId);
      _saveProducts();
    });
  }

  @override
  void initState() {
    super.initState();
    _initPreferences();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                productQuantities.putIfAbsent(product.Id, () => 1);

                if (!_quantityControllers.containsKey(product.Id)) {
                  _quantityControllers[product.Id] = TextEditingController(
                    text: productQuantities[product.Id].toString(),
                  );
                }

                return Card(
                  margin: EdgeInsets.all(8),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.Product_name,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('ID: ${product.Id}'),
                                  Text('Price per piece: ৳${product.Product_PerPcs_Price.toStringAsFixed(2)}'),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduct(product.Id),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    setState(() {
                                      if (productQuantities[product.Id]! > 1) {
                                        productQuantities[product.Id] =
                                            productQuantities[product.Id]! - 1;
                                        _quantityControllers[product.Id]!.text =
                                            productQuantities[product.Id]!
                                                .toString();
                                      }
                                    });
                                  },
                                ),
                                SizedBox(
                                  width: 60,
                                  child: TextFormField(
                                    controller:
                                        _quantityControllers[product.Id],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      isDense: true,
                                    ),
                                    style: TextStyle(fontSize: 16),
                                    onFieldSubmitted: (value) {
                                      final parsedValue =
                                          int.tryParse(value) ??
                                          productQuantities[product.Id]!;
                                      setState(() {
                                        productQuantities[product.Id] =
                                            parsedValue;
                                      });
                                      _quantityControllers[product.Id]!.text =
                                          parsedValue.toString();
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      productQuantities[product.Id] =
                                          productQuantities[product.Id]! + 1;
                                      _quantityControllers[product.Id]!.text =
                                          productQuantities[product.Id]!
                                              .toString();
                                    });
                                  },
                                ),
                              ],
                            ),
                            Text(
                              'Total: ৳${(product.Product_PerPcs_Price * productQuantities[product.Id]!).toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '৳${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FloatingActionButton(
                    onPressed: () async {
                      final newProduct = await _showNewDialog(context);
                      if (newProduct != null) {
                        setState(() {
                          selectedProducts.add(newProduct);
                          filteredProducts = List.from(selectedProducts);
                          _saveProducts();
                        });
                      }
                    },
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
