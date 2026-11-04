import assert from 'node:assert/strict';
import test from 'node:test';

import {
  MATCH,
  keywordPattern,
  matchKind,
  normalizeKeyword,
  readingPattern,
  toHiragana,
  toKatakana,
} from '../src/modules/search/search-match.js';

test('đổi qua lại hiragana và katakana, giữ nguyên ký tự khác', () => {
  assert.equal(toKatakana('げつ・つき ー A'), 'ゲツ・ツキ ー A');
  assert.equal(toHiragana('ゲツ・ガツ 月'), 'げつ・がつ 月');
});

test('từ khoá có ký tự regex được khớp nguyên văn, không thành cú pháp', () => {
  assert.ok(keywordPattern('C++').test('Lập trình C++ cơ bản'));
  assert.ok(!keywordPattern('C++').test('CCC'));
  assert.ok(keywordPattern('[').test('mở ngoặc ['));
  assert.ok(keywordPattern('A&B').test('Công ty A&B'));
  assert.ok(!keywordPattern('a.c').test('abc'));
});

test('khớp không phân biệt hoa thường và hiragana/katakana', () => {
  assert.ok(keywordPattern('nguyệt').test('NGUYỆT'));
  assert.ok(keywordPattern('げつ').test('ゲツ'));
  assert.ok(keywordPattern('ツキ').test('つき'));
});

test('âm Kun lưu kèm okurigana trong ngoặc vẫn khớp khi gõ liền', () => {
  assert.ok(readingPattern('たべる').test('た(べる)'));
  assert.ok(readingPattern('まなぶ').test('まな.ぶ'));
  assert.ok(readingPattern('つき').test('つき'));
  assert.ok(!keywordPattern('たべる').test('た(べる)'));
});

test('từ khoá được chuẩn hoá NFC để chữ Việt gõ tổ hợp vẫn khớp dữ liệu', () => {
  const typed = ' mặt trăng '.normalize('NFD');
  assert.equal(normalizeKeyword(typed), 'mặt trăng'.normalize('NFC'));
  assert.ok(keywordPattern(normalizeKeyword(typed)).test('Mặt trăng, tháng'));
});

test('mức khớp: nguyên văn, đầu chuỗi, chứa trong chuỗi, hoặc không khớp', () => {
  assert.equal(matchKind('月', '月'), MATCH.EXACT);
  assert.equal(matchKind('月曜日', '月'), MATCH.PREFIX);
  assert.equal(matchKind('今月', '月'), MATCH.CONTAINS);
  assert.equal(matchKind('学生', '月'), null);
  assert.equal(matchKind(null, '月'), null);
});

test('so từng ý trong nghĩa, từng phần tử mảng, bỏ okurigana và không phân biệt kana', () => {
  assert.equal(matchKind('Mặt trăng, tháng', 'tháng'), MATCH.EXACT);
  assert.equal(matchKind('Tình huống: Đi tàu', 'đi tàu'), MATCH.EXACT);
  assert.equal(matchKind('が (ga)', 'ga'), MATCH.EXACT);
  assert.equal(matchKind('[お]さら', 'さら'), MATCH.EXACT);
  assert.equal(matchKind(['ゲツ', 'ガツ'], 'がつ'), MATCH.EXACT);
  assert.equal(matchKind(['た(べる)', 'く(う)'], 'たべる'), MATCH.EXACT);
  assert.equal(matchKind('NGUYỆT', 'nguyệt'), MATCH.EXACT);
});
