import 'package:flutter/material.dart';

typedef String TitleF<T>(T item);

class ReorderState<T> extends State<Reorder<T>> {
  List<T>   _l;
  final TitleF<T> _titleF;

  ReorderState(List<T> l, TitleF<T> titleF): _l = l, _titleF = titleF;

  int _item = -1, _pos = -1; //"move item before pos"

  List<T> _buildList() {
    if (_item < 0 || _pos < 0)
      return _l;
    if (_item != _pos) {
      List<T> l = List.from(_l);
      l.removeAt(_item);
      l.insert(_pos, _l[_item]);
      return l;
    }
    return _l;
  }

  void _set(int item, int pos) {
    _item = item;
    _pos = pos;
    print("_set i=${item<0?'':_l[item]}[$item] p=${pos<0?'':_l[pos]}[$pos]");
  }

  void _unset() {
    print("_unset");
    _set(-1, -1);
  }

  void _commit() {
    print("_commit");
    setState(() { _l = _buildList(); });
    _set(-1, -1);
  }

  Widget _buildRow(String title, int index, BuildContext context) {
    return
      LongPressDraggable<int>(
        child: DragTarget<int>(
            builder: (c, x, y) { return title == null ? Divider() : ListTile(title: Text(title)); },
            onWillAccept: (j) { _set(j, index); return false; },
            onLeave: (j) { _unset(); },
            ),
        //childWhenDragging: ListTile(title: Text(title)),
        feedback: title == null ? Divider() : Text(title),
        data: index,
    );
  }

  List<Widget> _buildRowList() {
    var l = _buildList();
    var lr = <Widget>[];
    for (var i = 0; i < l.length; i++)
      lr.add(_buildRow(_titleF(l[i]), i, context));
    return lr;
  }

  final _biggerFont = const TextStyle(fontSize: 18.0);

  final _dropDecor = BoxDecoration(border: Border.all(color: Colors.blue, width: 1.0));
  final _dropDecorHi = BoxDecoration(border: Border.all(color: Colors.red, width: 3.0));

  Widget _dropPanel(bool hi, String text) {
    return Container(
        decoration: hi ? _dropDecorHi : _dropDecor,  //Theme.of(context).dividerColor
        child: Row(children: <Widget>[Expanded(child: Center(child: Text(text, style: _biggerFont)))])
    );
  }

  @override
  Widget build(BuildContext context) {
    return
      Dialog(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DragTarget<int>(
                    builder: (c, x, y) => _dropPanel(x.isNotEmpty, "To top"),
                    onWillAccept: (x) { _set(x, 0); return true; },
                    onLeave: (x) => _unset(),
                    onAccept: (x) => _commit()
                ),
                Expanded(child: DragTarget<int>(
                  builder: (c, x, y) => ListView(children: _buildRowList()),
                  onWillAccept: (x) => true,
                  onAccept: (x) => _commit()
                )),
                DragTarget<int>(
                    builder: (c, x, y) => _dropPanel(x.isNotEmpty, "To bottom"),
                    onWillAccept: (x) {  _set(x, _l.length - 1); return true; },
                    onLeave: (x) => _unset(),
                    onAccept: (x) => _commit()
                ),
                Row(
                  children: <Widget>[
                    FlatButton(
                        child: Text("Ok"),
                        onPressed: () => Navigator.pop(context, _l)
                    ),
                    FlatButton(
                        child: Text("Cancel"),
                        onPressed: () => Navigator.pop(context, null)
                    )
                  ],
                )
              ]
          )
      );

  }
}

class Reorder<T> extends StatefulWidget {
  final List<T>   _l;
  final TitleF<T> _titleF;

  Reorder(List<T> l, TitleF<T> titleF): _l = l, _titleF = titleF;

  @override
  State<StatefulWidget> createState() {
    return ReorderState(_l, _titleF);
  }
}
