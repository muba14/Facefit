// lib/widgets/portrait_painter.dart dosyasının birebir JS karşılığı (önizleme için).
const C = { ink: '#2A2421', accent: '#A8835A', accentSoft: '#EFE5D7', skin: '#F3E2CF', hair: '#3A2D27' };
const CX = 100, U = 46;

function geom(o) {
  const length = 2 * U * o.height * 0.92;
  const top = 128 - length / 2 + 6;
  const right = [[0, 0], [o.forehead * 0.7, 0.04], [o.forehead, 0.2], [o.cheek, 0.45], [(o.cheek + o.jaw) / 2, 0.61], [o.jaw, 0.77], [o.chin, 0.97], [0, 1]];
  const y = t => top + t * length;
  const halfAt = t => {
    for (let i = 0; i < right.length - 1; i++) {
      const a = right[i], b = right[i + 1];
      if (t >= a[1] && t <= b[1]) { const k = b[1] - a[1] === 0 ? 0 : (t - a[1]) / (b[1] - a[1]); return (a[0] + (b[0] - a[0]) * k) * U; }
    }
    return 0;
  };
  const facePts = () => [
    ...right.map(p => [CX + p[0] * U, y(p[1])]),
    ...right.slice().reverse().slice(1, right.length - 1).map(p => [CX - p[0] * U, y(p[1])]),
  ];
  return { length, top, y, halfAt, facePath: () => catmull(facePts(), true) };
}

function catmull(p, closed = false, path = new Path2D()) {
  path.moveTo(p[0][0], p[0][1]);
  const n = p.length, segs = closed ? n : n - 1;
  const at = i => closed ? p[(i + n) % n] : p[Math.max(0, Math.min(n - 1, i))];
  for (let i = 0; i < segs; i++) {
    const p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
    path.bezierCurveTo(p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6, p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6, p2[0], p2[1]);
  }
  if (closed) path.closePath();
  return path;
}

function rng(seed) { let s = seed; return () => { s = (s * 16807) % 2147483647; return (s - 1) / 2147483646; }; }

const NEUTRAL_HAIR = { top: 8, side: 3, sideDown: 0.42, texture: true };

function drawPortrait(canvas, outline, hair = NEUTRAL_HAIR, beard = { type: 'none' }) {
  const dpr = 2, W = canvas.clientWidth, H = canvas.clientHeight;
  canvas.width = W * dpr; canvas.height = H * dpr;
  const ctx = canvas.getContext('2d');
  const vx = 10, vy = 14, vw = 180, vh = 200;
  const s = Math.min(W / vw, H / vh);
  const tx = (W - vw * s) / 2 - vx * s, ty = (H - vh * s) / 2 - vy * s;
  ctx.setTransform(dpr * s, 0, 0, dpr * s, dpr * tx, dpr * ty);
  const g = geom(outline);
  hair = Object.assign({ fringe: 0, peakShift: 0, peakWidth: 1 }, hair);
  const stroke = (p, w = 1.6, col = C.ink) => { ctx.lineWidth = w; ctx.strokeStyle = col; ctx.lineCap = 'round'; ctx.lineJoin = 'round'; ctx.stroke(p); };
  const fill = (p, col, rule) => { ctx.fillStyle = col; ctx.fill(p, rule); };

  // boyun
  const nh = outline.jaw * U * 0.55;
  const neck = new Path2D();
  neck.moveTo(CX - nh, g.y(0.8)); neck.lineTo(CX - nh, 226); neck.quadraticCurveTo(CX - nh - 30, 230, CX - 80, 240);
  neck.lineTo(CX + 80, 240); neck.quadraticCurveTo(CX + nh + 30, 230, CX + nh, 226); neck.lineTo(CX + nh, g.y(0.8)); neck.closePath();
  fill(neck, C.skin); stroke(neck);
  const shirt = new Path2D();
  shirt.moveTo(CX - 80, 240); shirt.quadraticCurveTo(CX - nh - 26, 231, CX - nh - 2, 228); shirt.quadraticCurveTo(CX, 242, CX + nh + 2, 228);
  shirt.quadraticCurveTo(CX + nh + 26, 231, CX + 80, 240); shirt.closePath();
  fill(shirt, C.accentSoft);

  for (const d of [-1, 1]) {
    const e = new Path2D(); e.ellipse(CX + d * (g.halfAt(0.47) + 1), g.y(0.48), 5.5, g.length * 0.085, 0, 0, Math.PI * 2);
    fill(e, C.skin); stroke(e);
  }
  if (hair.sideDown > 0.7) drawHair(ctx, g, hair, true);
  const face = g.facePath();
  fill(face, C.skin); stroke(face);
  drawBeard(ctx, g, beard, s, tx, ty);
  drawFeatures(ctx, g, stroke);
  drawHair(ctx, g, hair, false);
}

function drawFeatures(ctx, g, stroke) {
  const eyeDx = g.halfAt(0.42) * 0.42, eyeY = g.y(0.43);
  for (const d of [-1, 1]) {
    const ex = CX + d * eyeDx;
    const e = new Path2D(); e.ellipse(ex, eyeY, 4.5, 2.75, 0, 0, Math.PI * 2); ctx.fillStyle = '#fff'; ctx.fill(e);
    const pu = new Path2D(); pu.arc(ex, eyeY, 2.2, 0, Math.PI * 2); ctx.fillStyle = C.ink; ctx.fill(pu);
    const b = new Path2D(); b.moveTo(ex - 8 * d, eyeY - 7); b.quadraticCurveTo(ex - d, eyeY - 11, ex + 8 * d, eyeY - 8);
    stroke(b, 2.6, C.hair);
  }
  const nose = new Path2D(); nose.moveTo(CX - 1, g.y(0.47)); nose.quadraticCurveTo(CX - 6, g.y(0.58), CX - 1, g.y(0.61)); nose.lineTo(CX + 4, g.y(0.6));
  stroke(nose, 1.3);
  const my = g.y(0.72), mw = g.halfAt(0.72) * 0.32;
  const lip = new Path2D(); lip.ellipse(CX, my + 1, mw + 2, 3, 0, 0, Math.PI * 2); ctx.fillStyle = C.skin; ctx.fill(lip);
  const m = new Path2D(); m.moveTo(CX - mw, my); m.quadraticCurveTo(CX, my + 3.5, CX + mw, my); stroke(m, 1.5);
}

function drawHair(ctx, g, hs, back) {
  const hy = g.y(0.17), crownY = g.top - hs.top * 1.6, fw = g.halfAt(0.2);
  const sideX = fw + 2 + hs.side * 0.7, sideT = hs.sideDown, sideBottomY = g.y(Math.min(sideT, 1.1));
  const hc = t => g.halfAt(Math.min(t, 1));
  ctx.fillStyle = C.hair;
  if (back) {
    const ob = Math.max(hc(sideT), fw * 0.8) + hs.side + 6;
    const p = new Path2D();
    p.moveTo(CX - ob, sideBottomY); p.quadraticCurveTo(CX - sideX - 4, g.y(0.5), CX - sideX, g.y(0.15));
    p.lineTo(CX + sideX, g.y(0.15)); p.quadraticCurveTo(CX + sideX + 4, g.y(0.5), CX + ob, sideBottomY); p.closePath();
    ctx.fill(p); return;
  }
  if (hs.bun) { const b = new Path2D(); b.arc(CX, crownY - 7, 10, 0, Math.PI * 2); ctx.fill(b); }
  const peakX = CX + hs.peakShift * U, pw = sideX * 0.55 * hs.peakWidth;
  const p = new Path2D();
  p.moveTo(CX - (hc(Math.min(sideT, 0.6)) + hs.side * 0.6 + 1), sideBottomY);
  p.lineTo(CX - sideX, g.y(0.22));
  p.bezierCurveTo(CX - sideX, g.top - hs.top * 0.35, peakX - pw, crownY, peakX, crownY);
  p.bezierCurveTo(peakX + pw, crownY, CX + sideX, g.top - hs.top * 0.35, CX + sideX, g.y(0.22));
  p.lineTo(CX + (hc(Math.min(sideT, 0.6)) + hs.side * 0.6 + 1), sideBottomY);
  const ist = Math.min(sideT, 1), templeX = fw * 0.86;
  p.lineTo(CX + hc(ist) - 3, sideBottomY);
  p.lineTo(CX + g.halfAt(0.3) - 3, g.y(0.3));
  p.lineTo(CX + templeX, hy);
  const fringeY = hy + hs.fringe * g.length * 0.16;
  if (hs.fringe > 0) {
    const teeth = 7;
    for (let i = 1; i <= teeth; i++) {
      const x = CX + templeX - 2 * templeX * i / teeth;
      p.lineTo(x, i === teeth ? hy : (i % 2 ? fringeY + 2 : fringeY - 4));
    }
  } else if (hs.part) p.quadraticCurveTo(CX, hy - 5, CX - templeX, hy + 1);
  else p.quadraticCurveTo(CX, hy - 7, CX - templeX, hy);
  p.lineTo(CX - g.halfAt(0.3) + 3, g.y(0.3));
  p.lineTo(CX - hc(ist) + 3, sideBottomY);
  p.closePath();
  ctx.fill(p);

  if (hs.undercut) {
    ctx.fillStyle = 'rgba(58,45,39,0.28)';
    for (const d of [-1, 1]) {
      const r = new Path2D();
      r.moveTo(CX + d * (fw - 2), g.y(0.2)); r.lineTo(CX + d * (sideX + 1), g.y(0.2));
      r.lineTo(CX + d * (g.halfAt(0.42) + 1), g.y(0.42)); r.lineTo(CX + d * (g.halfAt(0.42) - 3), g.y(0.42)); r.closePath();
      ctx.fill(r);
    }
  }
  ctx.strokeStyle = 'rgba(255,255,255,0.28)'; ctx.lineWidth = 1.2; ctx.lineCap = 'round';
  if (hs.slick) {
    for (let i = -2; i <= 2; i++) {
      const x0 = CX + i * templeX * 0.32, l = new Path2D();
      l.moveTo(x0, hy - 2); l.quadraticCurveTo(x0 + i * 2, crownY + hs.top * 0.25, peakX + i * pw * 0.35, crownY + 4); ctx.stroke(l);
    }
  } else if (hs.texture) {
    const r = rng(7);
    for (let i = 0; i < 9; i++) {
      const x0 = CX - templeX * 0.9 + r() * templeX * 1.8;
      const y0 = (hs.fringe > 0 ? fringeY - 6 : hy - 3) - r() * 4;
      const l = new Path2D(); l.moveTo(x0, y0); l.quadraticCurveTo(x0 + 3, (y0 + crownY) / 2, x0 + 6 + hs.peakShift * 20, crownY + 5 + r() * 4); ctx.stroke(l);
    }
  }
  if (hs.part) {
    const partX = CX - templeX * 0.45, l = new Path2D();
    l.moveTo(partX, hy - 1); l.quadraticCurveTo(partX - 2, (hy + crownY) / 2, partX + 4, crownY + hs.top * 0.35);
    ctx.save(); ctx.strokeStyle = C.skin; ctx.lineWidth = 1.6; ctx.stroke(l); ctx.restore();
    for (let i = 1; i <= 3; i++) {
      const q = new Path2D(); q.moveTo(partX + 4, hy - 4 - i * 4); q.quadraticCurveTo(CX + templeX * 0.4, crownY + 2 + i * 3, CX + sideX - 4, g.y(0.12) - i * 2); ctx.stroke(q);
    }
  }
}

function drawBeard(ctx, g, b, s, tx, ty) {
  if (!b || b.type === 'none') return;
  b = Object.assign({ length: 0, cheekLine: 0.55, stubble: false }, b);
  const col = b.stubble ? 'rgba(58,45,39,0.26)' : C.hair;
  const my = g.y(0.72), mw = g.halfAt(0.72) * 0.32;
  const mustache = () => { const p = new Path2D(); p.moveTo(CX - mw - 3, my + 1); p.quadraticCurveTo(CX - mw, g.y(0.64), CX, g.y(0.655)); p.quadraticCurveTo(CX + mw, g.y(0.64), CX + mw + 3, my + 1); p.quadraticCurveTo(CX, my - 3, CX - mw - 3, my + 1); p.closePath(); return p; };
  ctx.fillStyle = col;
  if (b.type === 'full') {
    const c = b.cheekLine, pts = [];
    for (let t = c; t <= 1.0001; t += 0.04) {
      const grow = b.length * Math.pow((t - c) / (1 - c), 1.4), half = g.halfAt(Math.min(t, 1));
      pts.push([CX - half - grow * 0.35, g.y(t) + grow * ((t - c) / (1 - c))]);
    }
    const rightPts = pts.slice().reverse().map(o => [2 * CX - o[0], o[1]]);
    const outline = [...pts, [CX, g.y(1) + b.length], ...rightPts];
    const p = catmull(outline);
    p.quadraticCurveTo(CX + g.halfAt(c) * 0.55, g.y(c + 0.06), CX + mw + 6, g.y(0.63));
    p.quadraticCurveTo(CX, g.y(0.6), CX - mw - 6, g.y(0.63));
    p.quadraticCurveTo(CX - g.halfAt(c) * 0.55, g.y(c + 0.06), outline[0][0], outline[0][1]);
    p.closePath();
    ctx.fill(p);
    if (b.stubble) {
      const r = rng(3); ctx.fillStyle = 'rgba(58,45,39,0.35)';
      const xs = outline.map(o => o[0]), ys = outline.map(o => o[1]).concat([g.y(0.6)]);
      const x0 = Math.min(...xs), x1 = Math.max(...xs), y0 = Math.min(...ys), y1 = Math.max(...ys);
      const m = ctx.getTransform();
      for (let i = 0; i < 160; i++) {
        const x = x0 + r() * (x1 - x0), y = y0 + r() * (y1 - y0);
        if (ctx.isPointInPath(p, m.a * x + m.e, m.d * y + m.f)) { const d = new Path2D(); d.arc(x, y, 0.55, 0, 7); ctx.fill(d); }
      }
    }
  } else if (b.type === 'goatee') {
    ctx.fill(mustache());
    const p = new Path2D(); p.moveTo(CX - mw * 0.7, my + 5); p.quadraticCurveTo(CX, my + 2, CX + mw * 0.7, my + 5);
    p.quadraticCurveTo(CX + mw * 0.8, g.y(1) + b.length * 0.6, CX, g.y(1) + b.length); p.quadraticCurveTo(CX - mw * 0.8, g.y(1) + b.length * 0.6, CX - mw * 0.7, my + 5); p.closePath();
    ctx.fill(p);
  } else if (b.type === 'circle') {
    const top = g.y(0.625), bot = g.y(1) + b.length;
    const ring = new Path2D(); ring.ellipse(CX, (top + bot) / 2, mw + 7, (bot - top) / 2, 0, 0, Math.PI * 2);
    ring.moveTo(CX + mw + 1, my + 1); ring.ellipse(CX, my + 1, mw + 1, 3.5, 0, 0, Math.PI * 2);
    ctx.save(); const clip = g.facePath(); clip.rect(0, g.y(0.9), 200, 240); ctx.clip(clip); ctx.fill(ring, 'evenodd'); ctx.restore();
  } else if (b.type === 'anchor') {
    ctx.fill(mustache());
    const p = new Path2D(); p.moveTo(CX - mw - 10, g.y(0.86)); p.quadraticCurveTo(CX, g.y(0.8), CX + mw + 10, g.y(0.86));
    p.quadraticCurveTo(CX + mw * 0.6, g.y(1), CX, g.y(1) + b.length); p.quadraticCurveTo(CX - mw * 0.6, g.y(1), CX - mw - 10, g.y(0.86)); p.closePath();
    ctx.fill(p); ctx.fillRect(CX - 2.5, my + 3.5, 5, 7);
  } else if (b.type === 'strap') {
    const pts = [];
    for (let t = 0.5; t <= 1.0001; t += 0.05) pts.push([CX - g.halfAt(Math.min(t, 1)), g.y(Math.min(t, 1))]);
    const line = [...pts, ...pts.slice().reverse().slice(1).map(o => [2 * CX - o[0], o[1]])];
    ctx.strokeStyle = C.hair; ctx.lineWidth = 4 + b.length; ctx.lineCap = 'round'; ctx.stroke(catmull(line));
  }
}

function drawOutline(canvas, outline, color = C.accent, sw = 2) {
  const dpr = 2, W = canvas.clientWidth, H = canvas.clientHeight;
  canvas.width = W * dpr; canvas.height = H * dpr;
  const ctx = canvas.getContext('2d');
  const g = geom(outline);
  const pts = []; // sınırlar
  const minY = g.top, maxY = g.top + g.length;
  let maxHalf = 0; for (let t = 0; t <= 1; t += 0.01) maxHalf = Math.max(maxHalf, g.halfAt(t));
  const bw = maxHalf * 2 + 4, bh = maxY - minY + 4;
  const s = Math.min(W / (bw + 8), H / (bh + 8));
  ctx.setTransform(dpr * s, 0, 0, dpr * s, dpr * (W / 2 - CX * s), dpr * (H / 2 - (minY + maxY) / 2 * s));
  const p = g.facePath();
  ctx.fillStyle = 'rgba(168,131,90,0.08)'; ctx.fill(p);
  ctx.setLineDash([7 / s * 1.6, 4 / s * 1.6]); ctx.lineWidth = sw / s; ctx.strokeStyle = color; ctx.lineCap = 'round'; ctx.stroke(p);
}
