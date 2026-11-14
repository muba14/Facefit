# HTML önizleme

README'deki ekran görüntüleri bu klasördeki önizlemeden alınır. Uygulamadaki çizim ve
yüz şekli hesaplaması (`portrait_painter.dart`, `face_analyzer.dart`) burada JS olarak aynen tekrarlanır
ve içerik aynı `assets/data/face_shapes.json` dosyasından okunur.

```bash
cd preview && npm install
cd .. && python3 -m http.server 8765
# tarayıcıda: http://localhost:8765/preview/index.html?s=home
# ekranlar: home, analyze, shapes, hair, beard, style, saved
```
