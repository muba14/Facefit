// Flutter ekranlarının HTML önizlemesi (README ekran görüntüleri için).
const screen = new URLSearchParams(location.search).get('s') || 'home';
const phone = document.getElementById('phone');
const ms = n => `<span class="ms">${n}</span>`;

const status = `<div class="status"><span>16:36</span><span>${ms('signal_cellular_alt')}${ms('wifi')}${ms('battery_full')}</span></div>`;
const nav = i => `<div class="nav">${[['center_focus_strong', 'Analiz'], ['face', 'Yüz Şekilleri'], ['favorite', 'Kaydedilenler']]
  .map(([ic, l], k) => `<div class="${k === i ? 'on' : ''}"><span class="pill">${ms(ic)}</span>${l}</div>`).join('')}</div>`;

fetch('../assets/data/face_shapes.json').then(r => r.json()).then(D => {
  const shape = id => D.shapes.find(s => s.id === id);
  const jobs = [];
  const portrait = (o, hair, beard, w, h) => { const id = 'c' + jobs.length; jobs.push(c => drawPortrait(c, o, hair, beard)); return `<canvas data-j="${jobs.length - 1}" style="width:${w}px;height:${h}px;display:block"></canvas>`; };
  const outline = (o, w, h, col, sw) => { jobs.push(c => drawOutline(c, o, col, sw)); return `<canvas data-j="${jobs.length - 1}" style="width:${w}px;height:${h}px;display:block"></canvas>`; };
  const brand = `<div class="brand"><div class="logo">${outline(shape('oval').outline, 22, 22, '#fff', 1.6)}</div>FaceFit</div>`;

  const styleCard = (sh, title, tags, why, hair, beard, fav) => `
    <div class="card style"><div class="pic">${portrait(sh.outline, hair, beard, 92, 110)}</div>
      <div style="flex:1"><div style="display:flex;align-items:center;margin-bottom:6px"><h4>${title}</h4><span class="ms heart ${fav ? 'on' : ''}">favorite</span></div>
      ${tags.map(t => `<span class="tag">${t}</span>`).join('')}<p>${why}</p></div></div>`;

  const detailHeader = (sh, tab, mine) => `${status}
    <div class="appbar">${ms('arrow_back')}${sh.name} yüz</div>
    <div style="padding:0 20px 14px">
      <div style="display:flex;gap:16px">${outline(sh.outline, 72, 88)}<div style="flex:1">${mine ? '<span class="tag ac">Senin yüz şeklin</span>' : ''}<div style="font-size:13.5px;line-height:1.45">${sh.summary}</div></div></div>
      <div style="margin-top:12px">${sh.traits.map(t => `<span class="tag">${t}</span>`).join('')}</div>
      <div class="goal" style="margin-top:6px">${ms('flag')}<span>${sh.goal}</span></div>
    </div>
    <div class="tabs">${['Saç', 'Sakal', 'Stil'].map((t, i) => `<div class="${i === tab ? 'on' : ''}">${t}</div>`).join('')}</div>`;

  let html = '';
  const my = shape('oval');

  if (screen === 'home') {
    const h = D.hairStyles[my.hair[0].id];
    html = `${status}<div class="scroll">${brand}
      <h1 style="margin-top:22px">Yüzüne en çok<br>yakışanı bul.</h1>
      <p class="muted" style="font-size:15px;line-height:1.4;margin-top:8px">Selfie çek; yüz şeklini ölçelim, sana uygun saç kesimi, sakal ve kombin fikirlerini çıkaralım.</p>
      <div class="card" style="background:var(--soft);margin-top:20px;padding:16px 8px 0 18px;display:flex;align-items:flex-end">
        <div style="flex:1;padding-bottom:18px"><div style="font-size:11px;letter-spacing:1.4px;color:var(--accent);font-weight:700">YÜZ ŞEKLİN</div>
        <div style="font-size:30px;font-weight:700;margin-top:6px">${my.name}</div>
        <div class="muted" style="font-size:13px;line-height:1.4;margin-top:8px">Önerilen: ${h.name}<br>Önerilerini görmek için dokun →</div></div>
        ${portrait(my.outline, h.spec, { type: 'none' }, 132, 158)}
      </div>
      <div class="btn fill" style="margin-top:16px">${ms('photo_camera')}Yeniden analiz et</div>
      <div class="btn out" style="margin-top:10px">${ms('photo_library')}Galeriden seç</div>
      <div class="sec" style="margin-top:24px">İyi bir fotoğraf için</div>
      <div class="row">${[['straighten', 'Saçını alnından geriye çek'], ['center_focus_strong', 'Kameraya düz bak'], ['wb_sunny', 'Önden gelen ışık']]
        .map(([i, t]) => `<div class="card" style="flex:1;padding:12px"><span class="ms" style="font-size:20px;color:var(--accent)">${i}</span><div style="font-size:12.5px;line-height:1.3;margin-top:8px">${t}</div></div>`).join('')}</div>
      <div style="display:flex;justify-content:space-between;align-items:center;margin-top:20px"><div class="sec">Yüz şekilleri</div><span style="color:var(--accent);font-weight:500;font-size:14px">Tümü</span></div>
      <div class="row" style="overflow:hidden">${D.shapes.map(s => `<div class="card" style="width:96px;flex:none;padding:10px;text-align:center">${outline(s.outline, 74, 80)}<div style="font-weight:500;font-size:13px;margin-top:6px">${s.name}</div></div>`).join('')}</div>
    </div>${nav(0)}`;
  }

  if (screen === 'analyze') {
    const h = D.hairStyles['quiff'];
    html = `${status}<div class="appbar">${ms('arrow_back')}Yüz analizi</div><div class="scroll" style="padding-top:4px">
      <div style="border-radius:20px;overflow:hidden;background:linear-gradient(#e9e3da,#d9d0c3);position:relative;height:330px">
        <div style="position:absolute;left:50%;top:6px;transform:translateX(-50%)">${portrait(my.outline, h.spec, { type: 'full', stubble: true, cheekLine: 0.52 }, 290, 322)}</div>
        <canvas id="ov" style="position:absolute;left:50%;top:6px;transform:translateX(-50%);width:290px;height:322px"></canvas>
      </div>
      <div class="card" style="margin-top:20px;display:flex;align-items:center;gap:16px">${outline(my.outline, 64, 76)}
        <div><div class="muted" style="font-size:13px">Yüz şeklin büyük ihtimalle</div><div style="font-size:28px;font-weight:700;letter-spacing:-.5px">Oval</div><div style="color:var(--accent);font-weight:500">%<span id="p0"></span> uyum</div></div></div>
      <div class="sec" style="margin-top:18px">Diğer olasılıklar</div><div id="others"></div>
      <div class="sec" style="margin-top:10px;margin-bottom:2px">Ölçümler</div><div class="muted" style="font-size:13px;margin-bottom:10px">Elmacık genişliğine göre oranlar</div>
      <div id="metrics" style="display:grid;grid-template-columns:1fr 1fr;gap:10px"></div>
    </div>`;
  }

  if (screen === 'shapes') {
    html = `${status}<div class="scroll" style="padding-top:16px"><h2>Yüz şekilleri</h2>
      <p class="muted" style="font-size:14px;margin-top:6px">Her şekil için saç, sakal ve stil önerilerini incele.</p>
      <div class="card" style="background:var(--soft);margin-top:14px"><b style="font-weight:700">Aynada kendin ölçmek istersen</b>
      <div style="font-size:13px;line-height:1.5;margin-top:8px">1. Alın genişliği  2. Elmacık kemikleri arası  3. Çene hattı genişliği  4. Saç çizgisinden çene ucuna uzunluk.<br>En geniş yer ve uzunluk/genişlik oranı şeklini belirler.</div></div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-top:12px">${D.shapes.map(s => `<div class="card" style="position:relative">
        ${s.id === 'oval' ? '<span class="tag ac" style="position:absolute;right:12px;top:12px">Sen</span>' : ''}${outline(s.outline, 140, 112)}
        <div style="font-size:17px;font-weight:700;margin-top:10px">${s.name}</div><div class="muted" style="font-size:12px;margin-top:2px">${s.traits.slice(0, 2).join(' · ')}</div></div>`).join('')}</div>
    </div>${nav(1)}`;
  }

  const det = { hair: 'round', beard: 'square', style: 'oblong' };
  if (screen === 'hair') {
    const sh = shape(det.hair);
    html = `${detailHeader(sh, 0, false)}<div class="scroll" style="padding-top:16px">${sh.hair.map((r, i) => {
      const h = D.hairStyles[r.id]; return styleCard(sh, h.name, [h.length, h.care], r.why, h.spec, { type: 'none' }, i === 0);
    }).join('')}</div>`;
  }
  if (screen === 'beard') {
    const sh = shape(det.beard);
    html = `${detailHeader(sh, 1, false)}<div class="scroll" style="padding-top:16px">${sh.beard.map((r, i) => {
      const b = D.beardStyles[r.id]; return styleCard(sh, b.name, [], r.why, NEUTRAL_HAIR, b.spec, i === 1);
    }).join('')}</div>`;
  }
  if (screen === 'style') {
    const sh = shape(det.style), g = sh.style;
    const guide = (ic, t, items) => `<div class="card" style="margin-bottom:10px"><div style="display:flex;gap:10px;align-items:center"><span class="ms" style="font-size:20px;color:var(--accent)">${ic}</span><b style="font-size:15px">${t}</b></div>
      ${items.map(x => `<div style="display:flex;gap:8px;margin-top:8px;font-size:13.5px;line-height:1.4"><span class="ms" style="font-size:15px;margin-top:2px">check</span>${x}</div>`).join('')}</div>`;
    html = `${status}<div class="appbar">${ms('arrow_back')}${sh.name} yüz</div>
      <div class="tabs">${['Saç', 'Sakal', 'Stil'].map((t, i) => `<div class="${i === 2 ? 'on' : ''}">${t}</div>`).join('')}</div>
      <div class="scroll" style="padding-top:16px">
      ${guide('checkroom', 'Yaka ve üst giyim', g.collars)}${guide('visibility', 'Gözlük çerçevesi', g.glasses)}
      <div class="avoid"><span class="ms" style="font-size:18px;color:var(--danger)">do_not_disturb_on</span><div><b>Kaçınılacaklar</b>${g.avoid.join('<br>')}</div></div>
      <div class="sec" style="margin-top:22px;margin-bottom:2px">Kombin fikirleri</div><div class="muted" style="font-size:13px;margin-bottom:10px">Yüz şekline uygun yaka ve aksesuarlarla</div>
      ${sh.outfits.slice(0, 2).map((o, i) => `<div class="card" style="margin-bottom:10px"><div style="display:flex;align-items:center;margin-bottom:6px"><b style="font-size:16px;flex:1">${o.name}</b><span class="ms heart ${i === 0 ? 'on' : ''}">favorite</span></div>
        <div>${o.palette.map(c => `<span class="dot" style="background:${c}"></span>`).join('')}</div>
        <div style="margin-top:10px">${o.items.map(x => `<div style="font-size:13.5px;line-height:1.35;margin-bottom:5px">·&nbsp; ${x}</div>`).join('')}</div></div>`).join('')}
    </div>`;
  }
  if (screen === 'saved') {
    const items = [
      ['hair', 'quiff', 'oval'], ['beard', 'short_boxed', 'oval'], ['hair', 'textured_crop', 'oval'], ['outfit', '0', 'oval'], ['hair', 'side_part', 'oval'],
    ];
    html = `${status}<div class="scroll" style="padding-top:16px"><h2>Kaydedilenler</h2>
      <p class="muted" style="font-size:14px;margin:6px 0 18px">Berbere göstermek için beğendiğin stiller burada.</p>
      ${items.map(([k, id, s]) => {
        const sh = shape(s); let title, sub, pic;
        if (k === 'hair') { const h = D.hairStyles[id]; title = h.name; sub = 'Saç'; pic = portrait(sh.outline, h.spec, { type: 'none' }, 56, 67); }
        else if (k === 'beard') { const b = D.beardStyles[id]; title = b.name; sub = 'Sakal'; pic = portrait(sh.outline, NEUTRAL_HAIR, b.spec, 56, 67); }
        else { const o = sh.outfits[+id]; title = o.name; sub = 'Kombin'; pic = `<div style="width:56px;height:67px;display:flex;flex-wrap:wrap;gap:3px;align-content:center;justify-content:center">${o.palette.slice(0, 4).map(c => `<span style="width:22px;height:22px;border-radius:50%;background:${c};border:1px solid var(--line)"></span>`).join('')}</div>`; }
        return `<div class="card" style="display:flex;align-items:center;gap:14px;padding:8px 12px 8px 10px;margin-bottom:10px"><div style="background:var(--bg);border-radius:10px;padding:4px 4px 0">${pic}</div>
          <div style="flex:1"><div style="font-weight:700;font-size:15.5px">${title}</div><div class="muted" style="font-size:13px;margin-top:2px">${sub} · ${sh.name} yüz</div></div><span class="ms heart on">favorite</span></div>`;
      }).join('')}
    </div>${nav(2)}`;
  }

  if (screen === 'icon' || screen === 'icon_fg') {
    const fg = screen === 'icon_fg';
    document.body.style.background = 'transparent'; document.body.style.margin = 0;
    phone.style.cssText = `width:512px;height:512px;margin:0;background:${fg ? 'transparent' : '#2A2421'}`;
    html = `<canvas id="ic" style="width:512px;height:512px;display:block"></canvas>`;
    if (html !== null) phone.innerHTML = html; html = null;
    const c = document.getElementById('ic'); c.width = 1024; c.height = 1024;
    const ctx = c.getContext('2d'); ctx.scale(2, 2);
    const k = fg ? 0.62 : 0.8; // adaptive ikon güvenli alanı
    ctx.translate(256, 256); ctx.scale(k, k); ctx.translate(-256, -256);
    const g = geom(my.outline), sc = 2.25;
    ctx.save(); ctx.translate(256 - CX * sc, 278 - (g.top + g.length / 2) * sc); ctx.scale(sc, sc);
    const p = g.facePath();
    ctx.setLineDash([9, 6.5]); ctx.lineWidth = 5; ctx.lineCap = 'round'; ctx.strokeStyle = '#F7F4EF'; ctx.stroke(p);
    ctx.setLineDash([]);
    // bronz saç kıvrımı (quiff)
    const q = new Path2D(), t = g.top;
    q.moveTo(CX - 44, t + 26); q.bezierCurveTo(CX - 46, t - 14, CX - 4, t - 30, CX + 30, t - 20);
    q.bezierCurveTo(CX + 50, t - 12, CX + 48, t + 8, CX + 44, t + 26);
    q.bezierCurveTo(CX + 20, t + 6, CX - 18, t + 6, CX - 44, t + 26); q.closePath();
    ctx.fillStyle = '#A8835A'; ctx.fill(q);
    ctx.restore();
  }
  if (html !== null) phone.innerHTML = html;
  document.querySelectorAll('canvas[data-j]').forEach(c => jobs[+c.dataset.j](c));

  const done = () => { document.body.dataset.ready = '1'; };
  if (screen === 'analyze') document.fonts.load('500 14px Roboto', 'AlınÇene').then(() => { analyzeDemo(D, my); done(); });
  else done();
});

// face_analyzer.dart'ın JS karşılığı — çizilmiş yüz üzerinde demo.
function analyzeDemo(D, sh) {
  const P = { oval: [1.29, .90, .77, .61], round: [1.03, .87, .80, .64], square: [1.08, .95, .94, .77], oblong: [1.53, .93, .88, .70], heart: [1.22, .99, .68, .52], diamond: [1.25, .74, .69, .55] };
  const W = [3, 4, 4, 2], T = 0.09;
  const g = geom(sh.outline);
  const pts = [];
  for (let t = 0; t <= 1; t += 0.02) pts.push([CX + g.halfAt(t), g.y(t)]);
  for (let t = 1; t >= 0; t -= 0.02) pts.push([CX - g.halfAt(t), g.y(t)]);
  const cut = g.y(0.1), poly = pts.map(([x, y]) => [x, Math.max(y, cut)]);
  const top = cut, bot = g.y(1), H = bot - top;
  const span = t => { const y = top + t * H + 1e-6, xs = []; for (let i = 0; i < poly.length; i++) { const a = poly[i], b = poly[(i + 1) % poly.length]; if ((a[1] <= y && b[1] > y) || (b[1] <= y && a[1] > y)) xs.push(a[0] + (y - a[1]) / (b[1] - a[1]) * (b[0] - a[0])); } return [Math.min(...xs), Math.max(...xs), y]; };
  const w = t => { const s = span(t); return s[1] - s[0]; };
  let ch = 0, cT = .45; for (let t = .3; t <= .58; t += .02) if (w(t) > ch) { ch = w(t); cT = t; }
  const v = [H / ch, w(.12) / ch, w(.78) / ch, w(.92) / w(.78)];
  const sc = Object.entries(P).map(([k, p]) => [k, Math.exp(-Math.sqrt(p.reduce((a, pi, i) => a + W[i] * (v[i] - pi) ** 2, 0)) / T)]);
  const sum = sc.reduce((a, b) => a + b[1], 0); sc.sort((a, b) => b[1] - a[1]);
  document.getElementById('p0').textContent = Math.round(sc[0][1] / sum * 100);
  const name = id => D.shapes.find(s => s.id === id).name;
  document.getElementById('others').innerHTML = sc.slice(1, 4).map(([k, x]) => `<div style="display:flex;align-items:center;margin-bottom:10px"><span style="width:92px;font-weight:500">${name(k)}</span><div class="bar"><i style="width:${x / sum * 100}%"></i></div><span class="muted" style="width:46px;text-align:right">%${Math.round(x / sum * 100)}</span></div>`).join('');
  document.getElementById('metrics').innerHTML = [['Uzunluk / genişlik', v[0]], ['Alın / elmacık', v[1]], ['Çene / elmacık', v[2]], ['Çene ucu daralması', v[3]]]
    .map(([l, x]) => `<div class="card" style="padding:10px 14px"><div style="font-size:20px;font-weight:700">${x.toFixed(2)}</div><div class="muted" style="font-size:12px">${l}</div></div>`).join('');

  // kontur + ölçüm çizgileri
  const c = document.getElementById('ov'), dpr = 2, Wd = c.clientWidth, Hd = c.clientHeight;
  c.width = Wd * dpr; c.height = Hd * dpr;
  const ctx = c.getContext('2d'), s = Math.min(Wd / 180, Hd / 200);
  ctx.setTransform(dpr * s, 0, 0, dpr * s, dpr * ((Wd - 180 * s) / 2 - 10 * s), dpr * ((Hd - 200 * s) / 2 - 14 * s));
  const path = new Path2D(); poly.forEach(([x, y], i) => i ? path.lineTo(x, y) : path.moveTo(x, y)); path.closePath();
  ctx.lineJoin = 'round';
  ctx.strokeStyle = '#fff'; ctx.lineWidth = 3.5 / s * 1.4; ctx.stroke(path);
  ctx.strokeStyle = C.accent; ctx.lineWidth = 2 / s * 1.4; ctx.stroke(path);
  ctx.font = `500 ${11 / s * 1.3}px Roboto, sans-serif`;
  for (const [l, t] of [['Alın', .12], ['Elmacık', cT], ['Çene', .78]]) {
    const [x0, x1, y] = span(t);
    ctx.strokeStyle = 'rgba(255,255,255,.95)'; ctx.lineWidth = 1.4 / s * 1.3; ctx.beginPath(); ctx.moveTo(x0, y); ctx.lineTo(x1, y); ctx.stroke();
    ctx.fillStyle = C.accent; for (const x of [x0, x1]) { ctx.beginPath(); ctx.arc(x, y, 2.2, 0, 7); ctx.fill(); }
    const tw = ctx.measureText(l).width;
    ctx.fillStyle = '#fff'; ctx.fillRect(x1 + 5, y - 7, tw + 6, 12); ctx.fillStyle = C.ink; ctx.fillText(l, x1 + 8, y + 3);
  }
  ctx.strokeStyle = 'rgba(255,255,255,.95)'; ctx.beginPath(); ctx.moveTo(CX, top); ctx.lineTo(CX, bot); ctx.stroke();
}
