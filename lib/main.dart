import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'mahasiswa.dart';
import 'prodi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Hive.deleteBoxFromDisk('mahasiswaBox');

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

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MahasiswaPage());
  }
}

class MahasiswaPage extends StatefulWidget {
  @override
  State<MahasiswaPage> createState() => _MahasiswaPageState();
}

class _MahasiswaPageState extends State<MahasiswaPage> {
  final Box box = Hive.box('mahasiswaBox');
  final Box prodiBox = Hive.box('prodiBox');

  final TextEditingController namaController = TextEditingController();
  final TextEditingController nimController = TextEditingController();

  int? selectedProdiId;
  int? editIndex;

  void saveData() {
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
      appBar: AppBar(title: Text("Data Mahasiswa")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: namaController,
              decoration: InputDecoration(labelText: "Nama"),
            ),
            TextField(
              controller: nimController,
              decoration: InputDecoration(labelText: "NIM"),
            ),
            DropdownButtonFormField<int>(
              key: ValueKey(selectedProdiId),
              initialValue: selectedProdiId,
              hint: Text("Pilih Prodi"),
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
            SizedBox(height: 10),
            ElevatedButton(onPressed: saveData, child: Text("Simpan")),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
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
