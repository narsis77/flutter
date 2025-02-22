// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'feedback_tester.dart';

/// Adds the basic requirements for a Chip.
Widget wrapForChip({
  required Widget child,
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
  Brightness brightness = Brightness.light,
  bool? useMaterial3,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness, useMaterial3: useMaterial3),
    home: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Material(child: child),
      ),
    ),
  );
}

Future<void> pumpCheckmarkChip(
  WidgetTester tester, {
  required Widget chip,
  Color? themeColor,
  Brightness brightness = Brightness.light,
  bool? useMaterial3,
}) async {
  await tester.pumpWidget(
    wrapForChip(
      useMaterial3: useMaterial3,
      brightness: brightness,
      child: Builder(
        builder: (BuildContext context) {
          final ChipThemeData chipTheme = ChipTheme.of(context);
          return ChipTheme(
            data: themeColor == null ? chipTheme : chipTheme.copyWith(
              checkmarkColor: themeColor,
            ),
            child: chip,
          );
        },
      ),
    ),
  );
}

Widget selectedFilterChip({ Color? checkmarkColor }) {
  return FilterChip(
    label: const Text('InputChip'),
    selected: true,
    showCheckmark: true,
    checkmarkColor: checkmarkColor,
    onSelected: (bool _) { },
  );
}

void expectCheckmarkColor(Finder finder, Color color) {
  expect(
    finder,
    paints
      // Physical model path
      ..path()
      // The first layer that is painted is the selection overlay. We do not care
      // how it is painted but it has to be added it to this pattern so that the
      // check mark can be checked next.
      ..rrect()
      // The second layer that is painted is the check mark.
      ..path(color: color),
  );
}

RenderBox getMaterialBox(WidgetTester tester, Finder type) {
  return tester.firstRenderObject<RenderBox>(
    find.descendant(
      of: type,
      matching: find.byType(CustomPaint),
    ),
  );
}

void checkChipMaterialClipBehavior(WidgetTester tester, Clip clipBehavior) {
  final Iterable<Material> materials = tester.widgetList<Material>(find.byType(Material));
  // There should be two Material widgets, first Material is from the "_wrapForChip" and
  // last Material is from the "RawChip".
  expect(materials.length, 2);
  // The last Material from `RawChip` should have the clip behavior.
  expect(materials.last.clipBehavior, clipBehavior);
}

Material getMaterial(WidgetTester tester) {
  return tester.widget<Material>(
    find.descendant(
      of: find.byType(FilterChip),
      matching: find.byType(Material),
    ),
  );
}

IconThemeData getIconData(WidgetTester tester) {
  final IconTheme iconTheme = tester.firstWidget(
    find.descendant(
      of: find.byType(RawChip),
      matching: find.byType(IconTheme),
    ),
  );
  return iconTheme.data;
}

DefaultTextStyle getLabelStyle(WidgetTester tester, String labelText) {
  return tester.widget(
    find.ancestor(
      of: find.text(labelText),
      matching: find.byType(DefaultTextStyle),
    ).first,
  );
}

// Finds any container of a tooltip.
Finder findTooltipContainer(String tooltipText) {
  return find.ancestor(
    of: find.text(tooltipText),
    matching: find.byType(Container),
  );
}

void main() {
  testWidgets('Material2 - FilterChip defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: false);
    const String label = 'filter chip';

    // Test enabled FilterChip defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: FilterChip(
              onSelected: (bool valueChanged) { },
              label: const Text(label),
            ),
          ),
        ),
      ),
    );

    // Test default chip size.
    expect(tester.getSize(find.byType(FilterChip)), const Size(178.0, 48.0));

    // Test default label style.
    expect(
      getLabelStyle(tester, label).style.color,
      theme.textTheme.bodyLarge!.color!.withAlpha(0xde),
    );

    Material chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, Colors.black);
    expect(chipMaterial.shape, const StadiumBorder());

    ShapeDecoration decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, Colors.black.withAlpha(0x1f));

    // Test disabled FilterChip defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: FilterChip(
            onSelected: null,
            label: Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, Colors.black);
    expect(chipMaterial.shape, const StadiumBorder());

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, Colors.black38);

    // Test selected enabled FilterChip defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: FilterChip(
            selected: true,
            onSelected: (bool valueChanged) { },
            label: const Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, Colors.black);
    expect(chipMaterial.shape, const StadiumBorder());

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, Colors.black.withAlpha(0x3d));

    // Test selected disabled FilterChip defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: FilterChip(
            selected: true,
            onSelected: null,
            label: Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, Colors.black);
    expect(chipMaterial.shape, const StadiumBorder());

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, Colors.black.withAlpha(0x3d));
  });

  testWidgets('Material3 - FilterChip defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    const String label = 'filter chip';

    // Test enabled FilterChip defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: FilterChip(
              onSelected: (bool valueChanged) { },
              label: const Text(label),
            ),
          ),
        ),
      ),
    );

    // Test default chip size.
    expect(
      tester.getSize(find.byType(FilterChip)),
      within(distance: 0.001, from: const Size(189.1, 48.0)),
    );
    // Test default label style.
    expect(
      getLabelStyle(tester, label).style.color!.value,
      theme.textTheme.labelLarge!.color!.value,
    );

    Material chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, Colors.transparent);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
    );

    ShapeDecoration decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, null);

    // Test disabled FilterChip defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: FilterChip(
            onSelected: null,
            label: Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, Colors.transparent);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.12)),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, null);

    // Test selected enabled FilterChip defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: FilterChip(
            selected: true,
            onSelected: (bool valueChanged) { },
            label: const Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, null);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, theme.colorScheme.secondaryContainer);

    // Test selected disabled FilterChip defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: FilterChip(
            selected: true,
            onSelected: null,
            label: Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, null);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, theme.colorScheme.onSurface.withOpacity(0.12));
  });

  testWidgets('Material3 - FilterChip.elevated defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    const String label = 'filter chip';

    // Test enabled FilterChip.elevated defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: FilterChip.elevated(
              onSelected: (bool valueChanged) { },
              label: const Text(label),
            ),
          ),
        ),
      ),
    );

    // Test default chip size.
    expect(
      tester.getSize(find.byType(FilterChip)),
      within(distance: 0.001, from: const Size(189.1, 48.0)),
    );
    // Test default label style.
    expect(
      getLabelStyle(tester, 'filter chip').style.color!.value,
      theme.textTheme.labelLarge!.color!.value,
    );

    Material chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 1);
    expect(chipMaterial.shadowColor, theme.colorScheme.shadow);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    ShapeDecoration decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, null);

    // Test disabled FilterChip.elevated defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: FilterChip.elevated(
            onSelected: null,
            label: Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, theme.colorScheme.shadow);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, theme.colorScheme.onSurface.withOpacity(0.12));

    // Test selected enabled FilterChip.elevated defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: FilterChip.elevated(
            selected: true,
            onSelected: (bool valueChanged) { },
            label: const Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 1);
    expect(chipMaterial.shadowColor, null);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, theme.colorScheme.secondaryContainer);

    // Test selected disabled FilterChip.elevated defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: FilterChip.elevated(
            selected: true,
            onSelected: null,
            label: Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, null);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, theme.colorScheme.onSurface.withOpacity(0.12));
  });

  testWidgets('FilterChip.color resolves material states', (WidgetTester tester) async {
    const Color disabledSelectedColor = Color(0xffffff00);
    const Color disabledColor = Color(0xff00ff00);
    const Color backgroundColor = Color(0xff0000ff);
    const Color selectedColor = Color(0xffff0000);
    final MaterialStateProperty<Color?> color = MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled) && states.contains(MaterialState.selected)) {
        return disabledSelectedColor;
      }
      if (states.contains(MaterialState.disabled)) {
        return disabledColor;
      }
      if (states.contains(MaterialState.selected)) {
        return selectedColor;
      }
      return backgroundColor;
    });
    Widget buildApp({ required bool enabled, required bool selected }) {
      return wrapForChip(
        child: Column(
          children: <Widget>[
            FilterChip(
              onSelected: enabled ? (bool value) { } : null,
              selected: selected,
              color: color,
              label: const Text('FilterChip'),
            ),
            FilterChip.elevated(
              onSelected: enabled ? (bool value) { } : null,
              selected: selected,
              color: color,
              label: const Text('FilterChip.elevated'),
            ),
          ],
        ),
      );
    }

    // Test enabled state.
    await tester.pumpWidget(buildApp(enabled: true, selected: false));

    // Enabled FilterChip should have the provided backgroundColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).first),
      paints..rrect(color: backgroundColor),
    );
    // Enabled elevated FilterChip should have the provided backgroundColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).last),
      paints..rrect(color: backgroundColor),
    );

    // Test disabled state.
    await tester.pumpWidget(buildApp(enabled: false, selected: false));
    await tester.pumpAndSettle();

    // Disabled FilterChip should have the provided disabledColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).first),
      paints..rrect(color: disabledColor),
    );
    // Disabled elevated FilterChip should have the provided disabledColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).last),
      paints..rrect(color: disabledColor),
    );

    // Test enabled & selected state.
    await tester.pumpWidget(buildApp(enabled: true, selected: true));
    await tester.pumpAndSettle();

    // Enabled & selected FilterChip should have the provided selectedColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).first),
      paints..rrect(color: selectedColor),
    );
    // Enabled & selected elevated FilterChip should have the provided selectedColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).last),
      paints..rrect(color: selectedColor),
    );

    // Test disabled & selected state.
    await tester.pumpWidget(buildApp(enabled: false, selected: true));
    await tester.pumpAndSettle();

    // Disabled & selected FilterChip should have the provided disabledSelectedColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).first),
      paints..rrect(color: disabledSelectedColor),
    );
    // Disabled & selected elevated FilterChip should have the
    // provided disabledSelectedColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).last),
      paints..rrect(color: disabledSelectedColor),
    );
  });

  testWidgets('FilterChip uses provided state color properties', (WidgetTester tester) async {
    const Color disabledColor = Color(0xff00ff00);
    const Color backgroundColor = Color(0xff0000ff);
    const Color selectedColor = Color(0xffff0000);
    Widget buildApp({ required bool enabled, required bool selected }) {
      return wrapForChip(
        child: Column(
          children: <Widget>[
            FilterChip(
              onSelected: enabled ? (bool value) { } : null,
              selected: selected,
              disabledColor: disabledColor,
              backgroundColor: backgroundColor,
              selectedColor: selectedColor,
              label: const Text('FilterChip'),
            ),
            FilterChip.elevated(
              onSelected: enabled ? (bool value) { } : null,
              selected: selected,
              disabledColor: disabledColor,
              backgroundColor: backgroundColor,
              selectedColor: selectedColor,
              label: const Text('FilterChip.elevated'),
            ),
          ],
        ),
      );
    }

    // Test enabled state.
    await tester.pumpWidget(buildApp(enabled: true, selected: false));

    // Enabled FilterChip should have the provided backgroundColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).first),
      paints..rrect(color: backgroundColor),
    );
    // Enabled elevated FilterChip should have the provided backgroundColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).last),
      paints..rrect(color: backgroundColor),
    );

    // Test disabled state.
    await tester.pumpWidget(buildApp(enabled: false, selected: false));
    await tester.pumpAndSettle();

    // Disabled FilterChip should have the provided disabledColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).first),
      paints..rrect(color: disabledColor),
    );
    // Disabled elevated FilterChip should have the provided disabledColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).last),
      paints..rrect(color: disabledColor),
    );

    // Test enabled & selected state.
    await tester.pumpWidget(buildApp(enabled: true, selected: true));
    await tester.pumpAndSettle();

    // Enabled & selected FilterChip should have the provided selectedColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).first),
      paints..rrect(color: selectedColor),
    );
    // Enabled & selected elevated FilterChip should have the provided selectedColor.
    expect(
      getMaterialBox(tester, find.byType(RawChip).last),
      paints..rrect(color: selectedColor),
    );
  });

  testWidgets('FilterChip can be tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FilterChip(
            onSelected: (bool valueChanged) { },
            label: const Text('filter chip'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(FilterChip));
    expect(tester.takeException(), null);
  });

  testWidgets('Material2 - Filter chip check mark color is determined by platform brightness when light', (WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedFilterChip(),
      useMaterial3: false,
    );

    expectCheckmarkColor(find.byType(FilterChip), Colors.black.withAlpha(0xde));
  });

  testWidgets('Material3 - Filter chip check mark color is determined by platform brightness when light', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    await pumpCheckmarkChip(
      tester,
      chip: selectedFilterChip(),
      useMaterial3: theme.useMaterial3,
    );

    expectCheckmarkColor(
      find.byType(FilterChip),
      theme.colorScheme.onSecondaryContainer,
    );
  });

  testWidgets('Material2 - Filter chip check mark color is determined by platform brightness when dark', (WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedFilterChip(),
      brightness: Brightness.dark,
      useMaterial3: false,
    );

    expectCheckmarkColor(
      find.byType(FilterChip),
      Colors.white.withAlpha(0xde),
    );
  });

  testWidgets('Material3 - Filter chip check mark color is determined by platform brightness when dark', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(brightness: Brightness.dark);
    await pumpCheckmarkChip(
      tester,
      chip: selectedFilterChip(),
      brightness: theme.brightness,
      useMaterial3: theme.useMaterial3,
    );

    expectCheckmarkColor(
      find.byType(FilterChip),
      theme.colorScheme.onSecondaryContainer,
    );
  });

  testWidgets('Filter chip check mark color can be set by the chip theme', (WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedFilterChip(),
      themeColor: const Color(0xff00ff00),
    );

    expectCheckmarkColor(find.byType(FilterChip), const Color(0xff00ff00));
  });

  testWidgets('Filter chip check mark color can be set by the chip constructor', (WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedFilterChip(checkmarkColor: const Color(0xff00ff00)),
    );

    expectCheckmarkColor(find.byType(FilterChip), const Color(0xff00ff00));
  });

  testWidgets('Filter chip check mark color is set by chip constructor even when a theme color is specified', (WidgetTester tester) async {
    await pumpCheckmarkChip(
      tester,
      chip: selectedFilterChip(checkmarkColor: const Color(0xffff0000)),
      themeColor: const Color(0xff00ff00),
    );

    expectCheckmarkColor(find.byType(FilterChip), const Color(0xffff0000));
  });

  testWidgets('FilterChip clipBehavior properly passes through to the Material', (WidgetTester tester) async {
    const Text label = Text('label');
    await tester.pumpWidget(wrapForChip(child: FilterChip(label: label, onSelected: (bool b) { })));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(wrapForChip(child: FilterChip(label: label, onSelected: (bool b) { }, clipBehavior: Clip.antiAlias)));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });

  testWidgets('Material3 - width should not change with selection', (WidgetTester tester) async {
    // Regression tests for: https://github.com/flutter/flutter/issues/110645

    // For the text "FilterChip" the chip should default to 175 regardless of selection.
    const int expectedWidth = 175;

    // Unselected
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Center(
          child: FilterChip(
            label: const Text('FilterChip'),
            showCheckmark: false,
            onSelected: (bool _) {},
         )
        ),
      ),
    ));
    expect(tester.getSize(find.byType(FilterChip)).width, expectedWidth);

    // Selected
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Center(
            child: FilterChip(
              label: const Text('FilterChip'),
              showCheckmark: false,
              selected: true,
              onSelected: (bool _) {},
            )
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(FilterChip)).width, expectedWidth);
  });

  testWidgets('FilterChip uses provided iconTheme', (WidgetTester tester) async {
    Widget buildChip({ IconThemeData? iconTheme }) {
      return MaterialApp(
        home: Material(
          child: FilterChip(
            iconTheme: iconTheme,
            avatar: const Icon(Icons.add),
            label: const Text('FilterChip'),
            onSelected: (bool _) {},
          ),
        ),
      );
    }

    // Test default icon theme.
    await tester.pumpWidget(buildChip());

    expect(getIconData(tester).color, ThemeData().iconTheme.color);

    // Test provided icon theme.
    await tester.pumpWidget(buildChip(iconTheme: const IconThemeData(color: Color(0xff00ff00))));

    expect(getIconData(tester).color, const Color(0xff00ff00));
  });

  testWidgets('Material3 - FilterChip supports delete button', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: FilterChip(
              onDeleted: () { },
              onSelected: (bool valueChanged) { },
              label: const Text('FilterChip'),
            ),
          ),
        ),
      ),
    );

    // Test the chip size with delete button.
    expect(find.text('FilterChip'), findsOneWidget);
    expect(tester.getSize(find.byType(FilterChip)), const Size(195.0, 48.0));

    // Test the delete button icon.
    expect(tester.getSize(find.byIcon(Icons.clear)), const Size(18.0, 18.0));
    expect(getIconData(tester).color, theme.colorScheme.onSecondaryContainer);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: FilterChip.elevated(
              onDeleted: () { },
              onSelected: (bool valueChanged) { },
              label: const Text('Elevated FilterChip'),
            ),
          ),
        ),
      ),
    );

    // Test the elevated chip size with delete button.
    expect(find.text('Elevated FilterChip'), findsOneWidget);
    expect(
      tester.getSize(find.byType(FilterChip)),
      within(distance: 0.001, from: const Size(321.9, 48.0)),
    );

    // Test the delete button icon.
    expect(tester.getSize(find.byIcon(Icons.clear)), const Size(18.0, 18.0));
    expect(getIconData(tester).color, theme.colorScheme.onSecondaryContainer);
  }, skip: kIsWeb && !isCanvasKit); // https://github.com/flutter/flutter/issues/99933

  testWidgets('Material2 - FilterChip supports delete button', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: false);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: FilterChip(
              onDeleted: () { },
              onSelected: (bool valueChanged) { },
              label: const Text('FilterChip'),
            ),
          ),
        ),
      ),
    );

    // Test the chip size with delete button.
    expect(find.text('FilterChip'), findsOneWidget);
    expect(tester.getSize(find.byType(FilterChip)), const Size(188.0, 48.0));

    // Test the delete button icon.
    expect(tester.getSize(find.byIcon(Icons.cancel)), const Size(18.0, 18.0));
    expect(getIconData(tester).color, theme.iconTheme.color?.withAlpha(0xde));

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: FilterChip.elevated(
              onDeleted: () { },
              onSelected: (bool valueChanged) { },
              label: const Text('Elevated FilterChip'),
            ),
          ),
        ),
      ),
    );

    // Test the elevated chip size with delete button.
    expect(find.text('Elevated FilterChip'), findsOneWidget);
    expect(tester.getSize(find.byType(FilterChip)), const Size(314.0, 48.0));

    // Test the delete button icon.
    expect(tester.getSize(find.byIcon(Icons.cancel)), const Size(18.0, 18.0));
    expect(getIconData(tester).color, theme.iconTheme.color?.withAlpha(0xde));
  });

  testWidgets('Customize FilterChip delete button', (WidgetTester tester) async {
    Widget buildChip({
      Widget? deleteIcon,
      Color? deleteIconColor,
      String? deleteButtonTooltipMessage,
    }) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: FilterChip(
              deleteIcon: deleteIcon,
              deleteIconColor: deleteIconColor,
              deleteButtonTooltipMessage: deleteButtonTooltipMessage,
              onDeleted: () { },
              onSelected: (bool valueChanged) { },
              label: const Text('FilterChip'),
            ),
          ),
        ),
      );
    }

    // Test the custom delete icon.
    await tester.pumpWidget(buildChip(deleteIcon: const Icon(Icons.delete)));

    expect(find.byIcon(Icons.clear), findsNothing);
    expect(find.byIcon(Icons.delete), findsOneWidget);

    // Test the custom delete icon color.
    await tester.pumpWidget(buildChip(
      deleteIcon: const Icon(Icons.delete),
      deleteIconColor: const Color(0xff00ff00)),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.clear), findsNothing);
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(getIconData(tester).color, const Color(0xff00ff00));

    // Test the custom delete button tooltip message.
    await tester.pumpWidget(buildChip(deleteButtonTooltipMessage: 'Delete FilterChip'));
    await tester.pumpAndSettle();

    // Hover over the delete icon of the chip
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byIcon(Icons.clear)));

    await tester.pumpAndSettle();

    // Verify the tooltip message is set.
    expect(find.widgetWithText(Tooltip, 'Delete FilterChip'), findsOneWidget);

    await gesture.up();
  });

  testWidgets('FilterChip delete button control test', (WidgetTester tester) async {
    final FeedbackTester feedback = FeedbackTester();
    final List<String> deletedButtonStrings = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: FilterChip(
              onDeleted: () {
                deletedButtonStrings.add('A');
               },
              onSelected: (bool valueChanged) { },
              label: const Text('FilterChip'),
            ),
          ),
        ),
      ),
    );

    expect(feedback.clickSoundCount, 0);

    expect(deletedButtonStrings, isEmpty);
    await tester.tap(find.byIcon(Icons.clear));
    expect(deletedButtonStrings, equals(<String>['A']));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(feedback.clickSoundCount, 1);

    await tester.tap(find.byIcon(Icons.clear));
    expect(deletedButtonStrings, equals(<String>['A', 'A']));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(feedback.clickSoundCount, 2);

    feedback.dispose();
  });

  testWidgets('Delete button is visible on disabled FilterChip', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapForChip(
        child: FilterChip(
          label: const Text('Label'),
          onSelected: null,
          onDeleted: () { },
        )
      ),
    );

    // Delete button should be visible.
    expectLater(find.byType(RawChip), matchesGoldenFile('filter_chip.disabled.delete_button.png'));
  });

  testWidgets('Delete button tooltip is not shown on disabled FilterChip', (WidgetTester tester) async {
    Widget buildChip({ bool enabled = true }) {
      return wrapForChip(
        child: FilterChip(
          onSelected: enabled ? (bool value) { } : null,
          label: const Text('Label'),
          onDeleted: () { },
        )
      );
    }

    // Test enabled chip.
    await tester.pumpWidget(buildChip());

    final Offset deleteButtonLocation = tester.getCenter(find.byType(Icon));
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.moveTo(deleteButtonLocation);
    await tester.pump();

    // Delete button tooltip should be visible.
    expect(findTooltipContainer('Delete'), findsOneWidget);

    // Test disabled chip.
    await tester.pumpWidget(buildChip(enabled: false));
    await tester.pump();

    // Delete button tooltip should not be visible.
    expect(findTooltipContainer('Delete'), findsNothing);
  });
}
