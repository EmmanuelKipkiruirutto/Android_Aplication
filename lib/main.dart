import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'style.dart';
import 'package:carousel_slider/carousel_slider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Management System',
      theme: AppStyles.appTheme,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restaurant Management System'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TablePage()),
              );
            },
            child: Text('Manage Tables'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => KitchenPage()),
              );
            },
            child: Text('Kitchen Interface'),
          ),
        ],
      ),
    );
  }
}

class TablePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tables'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2,
        ),
        itemCount: 10, // Example: 10 tables
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodCategoryPage(tableNumber: index + 1),
                ),
              );
            },
            child: Card(
              child: Center(
                child: Text('Table ${index + 1}'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class FoodCategoryPage extends StatelessWidget {
  final int tableNumber;

  FoodCategoryPage({required this.tableNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Categories (Table $tableNumber)'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DBHelper().fetchFoodCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final categories = snapshot.data!;
            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category['name']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FoodPage(
                          tableNumber: tableNumber,
                          categoryId: category['id'],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class FoodPage extends StatefulWidget {
  final int tableNumber;
  final int categoryId;

  FoodPage({required this.tableNumber, required this.categoryId});

  @override
  _FoodPageState createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  double _totalBill = 0.0;

  void _addFoodToOrder(int foodId, double price) async {
    await DBHelper().insertOrder(widget.tableNumber, foodId);
    setState(() {
      _totalBill += price;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order added for Table ${widget.tableNumber}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Foods (Table ${widget.tableNumber})'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'Total Bill: \$$_totalBill',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DBHelper().fetchFoods(widget.categoryId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final foods = snapshot.data!;
                  return ListView.builder(
                    itemCount: foods.length,
                    itemBuilder: (context, index) {
                      final food = foods[index];
                      return ListTile(
                        title: Text('${food['name']} - \$${food['price']}'),
                        onTap: () {
                          _addFoodToOrder(food['id'], food['price']);
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class KitchenPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kitchen Orders'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DBHelper().fetchOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final orders = snapshot.data!;
            var ordersByTable = <int, List<Map<String, dynamic>>>{};
            for (var order in orders) {
              ordersByTable.putIfAbsent(order['table_number'], () => []).add(order);
            }
            return ListView.builder(
              itemCount: ordersByTable.keys.length,
              itemBuilder: (context, index) {
                final tableNumber = ordersByTable.keys.elementAt(index);
                final tableOrders = ordersByTable[tableNumber]!;
                return ExpansionTile(
                  title: Text('Table $tableNumber'),
                  children: tableOrders.map((order) {
                    return ListTile(
                      title: Text('Food ID: ${order['food_id']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () async {
                          await DBHelper().clearOrder(tableNumber);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Order for Table $tableNumber fulfilled')),
                          );
                          (context as Element).reassemble();
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            );
          }
        },
      ),
    );
  }
}