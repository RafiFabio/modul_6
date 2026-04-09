import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'mahasiswa.dart';
import 'prodi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(MahasiswaAdapter());
  Hive.registerAdapter(ProdiAdapter());

  await Hive.openBox<Mahasiswa>('mahasiswaBox');
  await Hive.openBox<Prodi>('prodiBox');

  var prodiBox = Hive.box<Prodi>('prodiBox');

  if (prodiBox.isEmpty) {
    prodiBox.addAll([
      Prodi(namaProdi: "Informatika"),
      Prodi(namaProdi: "Biologi"),
      Prodi(namaProdi: "Fisika"),
    ]);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Box<Mahasiswa> box = Hive.box<Mahasiswa>('mahasiswaBox');
  final Box<Prodi> prodiBox = Hive.box<Prodi>('prodiBox');

  final namaController = TextEditingController();
  final nimController = TextEditingController();

  int? selectedProdiId;
  int? editIndex;

  void saveData() {
    if (selectedProdiId == null) return;

    final mahasiswa = Mahasiswa(
      nama: namaController.text,
      nim: nimController.text,
      prodiId: selectedProdiId!,
    );

    if (editIndex == null) {
      box.add(mahasiswa);
    } else {
      box.putAt(editIndex!, mahasiswa);
      editIndex = null;
    }

    clearForm();
  }

  void editData(int index) {
    final data = box.getAt(index)!;

    namaController.text = data.nama;
    nimController.text = data.nim;
    selectedProdiId = data.prodiId;

    setState(() {
      editIndex = index;
    });
  }

  void deleteData(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Data"),
        content: const Text("Yakin ingin menghapus data ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              // 🔥 FIX UTAMA
              if (editIndex == index) {
                clearForm(); // reset form jika data yg diedit dihapus
              } else if (editIndex != null && index < editIndex!) {
                editIndex = editIndex! - 1; // sesuaikan index
              }

              box.deleteAt(index);
              Navigator.pop(context);
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  void clearForm() {
    namaController.clear();
    nimController.clear();
    selectedProdiId = null;

    setState(() {
      editIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mahasiswa")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: "Nama"),
            ),
            TextField(
              controller: nimController,
              decoration: const InputDecoration(labelText: "NIM"),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<int>(
              value: selectedProdiId,
              hint: const Text("Pilih Prodi"),
              items: List.generate(prodiBox.length, (index) {
                final prodi = prodiBox.getAt(index);
                return DropdownMenuItem(
                  value: index,
                  child: Text(prodi!.namaProdi),
                );
              }),
              onChanged: (value) {
                setState(() {
                  selectedProdiId = value;
                });
              },
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: saveData,
              child: Text(editIndex == null ? "Simpan" : "Update"),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ValueListenableBuilder(
                valueListenable: box.listenable(),
                builder: (context, Box<Mahasiswa> box, _) {
                  return ListView.builder(
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      final data = box.getAt(index)!;
                      final prodi = prodiBox.getAt(data.prodiId);

                      return ListTile(
                        title: Text(data.nama),
                        subtitle: Text(
                          "NIM: ${data.nim} | ${prodi?.namaProdi ?? '-'}",
                        ),
                        onTap: () => editData(index),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => editData(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteData(index),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}