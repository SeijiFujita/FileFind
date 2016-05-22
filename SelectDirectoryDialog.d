// Written in the D programming language.
/*
 * dmd 2.070.0
 *
 * Copyright Seiji Fujita 2016.
 * Distributed under the Boost Software License, Version 1.0.
 * http://www.boost.org/LICENSE_1_0.txt
 */

module SelectDirectoryDialog;

import org.eclipse.swt.all;
//import java.lang.all;

import std.file;
import std.path;
import std.string;

import dlsbuffer;


class SelectDirectoryDialog : Dialog
{
private:
	Shell shell;
	Text text;
	Tree tree;
    string selectDirectoryPath;
	bool  dialogResult;
public:
	this(Shell parent) {
		super(parent, checkStyle(parent, SWT.APPLICATION_MODAL));
	}
	string open(string selectdir = null) {
		setDirectoryPath(selectdir);
		createContents();
		shell.open();
		// shell.layout();
		Display display = getParent().getDisplay();
		while (!shell.isDisposed()) {
			if (!display.readAndDispatch())
				display.sleep();
		}
		if (dialogResult) {
			return selectDirectoryPath;
		}
		return null;
	}
	void setDirectoryPath(string newdir) {
		if (newdir !is null && newdir.length > 0 && newdir.exists() && newdir.isDir()) {
			selectDirectoryPath = buildNormalizedPath(newdir);
		} else {
			selectDirectoryPath = getcwd();
		}
	}
	void createContents() {
		shell = new Shell(getParent(), getStyle() | SWT.DIALOG_TRIM | SWT.RESIZE);
		// shell = new Shell(getParent(), getStyle() | SWT.RESIZE | SWT.BORDER | SWT.TITLE | SWT.MIN | SWT.MAX | SWT.CLOSE | SWT.APPLICATION_MODAL);
		shell.setSize(400, 500);
		shell.setText("Select Directory");
		shell.setLayout(new GridLayout(1, false));
		
		//
		Composite comp = new Composite(shell, SWT.NONE);
		GridData gdata = new GridData(GridData.FILL_BOTH);
		comp.setLayoutData(gdata);
		comp.setLayout(new GridLayout(1, false));

		createLabel(comp, "Select Directory:");
		
		createEditBox(comp);
		
		createTreeView(comp);
		
		createHorizotalLine(shell);
		
		// ok, cancel bottom
		Composite bottom = createRightAlignmentComposite();
		Button okBtn = createButton(bottom, SWT.PUSH, "OK", BUTTON_WIDTH);
		void onSelection_okBtn(SelectionEvent e) {
			dialogResult = true;
			shell.close();
		}
		okBtn.addSelectionListener(
			dgSelectionListener(SelectionListener.SELECTION, &onSelection_okBtn)
		);
		Button cancelBtn = createButton(bottom, SWT.PUSH, "キャンセル", BUTTON_WIDTH);
		void onSelection_canselBtn(SelectionEvent e) {
			dialogResult = false;
			shell.close();
		}
		cancelBtn.addSelectionListener(
			dgSelectionListener(SelectionListener.SELECTION, &onSelection_canselBtn)
		);
		
	}
//-----------------------------------------
	void createEditBox(Composite parent) {
		Composite c = new Composite(parent, SWT.NONE);
		GridData gdata = new GridData(GridData.FILL_HORIZONTAL);
		c.setLayoutData(gdata);
		c.setLayout(new GridLayout(2, false));
		
		text = new Text(c, SWT.SINGLE | SWT.BORDER);
		gdata = new GridData(GridData.FILL_HORIZONTAL);
		text.setLayoutData(gdata);
		text.setText(selectDirectoryPath);
		
		Button updir = createButton(c, SWT.PUSH, "←", 30);
		void onSelection_updir(SelectionEvent e) {
			dlog("onSelection_updir.text.getText() = ", text.getText());
			string newdir = buildNormalizedPath(dirName(text.getText()));
			dlog("onSelection_updir.newdir = ", newdir);
			text.setText(newdir);
			folderUpdate();
		}
		updir.addSelectionListener(
			dgSelectionListener(SelectionListener.SELECTION, &onSelection_updir)
		);
	}
//-----------------------------------------
	void createTreeView(Composite parent) {
		Composite c = new Composite(parent, SWT.NONE);
		GridData gdata = new GridData(GridData.FILL_BOTH);
		c.setLayoutData(gdata);
		c.setLayout(new GridLayout(2, false));
		
		tree = new Tree(c, SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL | SWT.SINGLE);
		tree.setLayoutData(new GridData(GridData.FILL_BOTH));
		// tree.setLinesVisible(true);
		
		tree.addListener(SWT.MouseDoubleClick, new class Listener {
			public void handleEvent(Event event) {
				if (event.button == 1) { // mouse left button
					// Point point = new Point(event.x, event.y);
					// TreeFolderItem item = cast(TreeFolderItem)tree.getItem(point);
					auto items = cast(TreeFolderItem[])tree.getSelection();
					if (items !is null && items.length >= 1) {
						dlog("MouseDoubleClick: ", items[0].getfullPath());
						text.setText(items[0].getfullPath());
						folderUpdate();
					}
				}
			}
		});
version (none) {
		tree.addTreeListener(new class TreeAdapter {
			override void treeExpanded(TreeEvent event) {
/*				TreeItem item = (TreeItem) event.item;
				Image image = (Image) item.getData(TREEITEMDATA_IMAGEEXPANDED);
				if (image != null)
					item.setImage(image);
				treeExpandItem(item);
*/
			}
			override void treeCollapsed(TreeEvent event) {
/*				TreeItem item = (TreeItem) event.item;
				Image image = (Image) item.getData(TREEITEMDATA_IMAGECOLLAPSED);
				if (image != null)
					item.setImage(image);
*/
			}
		});
} // version (none)
//		createTreeDragSource(tree);
//		createTreeDropTarget(tree);
		folderUpdate();
	}
	void folderUpdate() {
		setDirectoryPath(text.getText());
		setFolder(tree, selectDirectoryPath);
	}
	void setFolder(Tree node, string path) {
		node.removeAll();
		TreeFolderItem item = new TreeFolderItem(node, SWT.NONE);
		item.setText(path);
		foreach (DirEntry e; dirEntries(path, SpanMode.shallow)) {
			if (e.isDir()) {
				item.addPath(item, e.name);
			}
		}
		item.setExpanded(true);
	}
	
	class TreeFolderItem : TreeItem
	{
		private string fullPath;
		
		this(TreeFolderItem parentItem, int style) {
			super(parentItem, style);
		}
		this(Tree parent, int style) {
			super(parent, style);
		}
		
		string getfullPath() {
			return fullPath;
		}
		TreeFolderItem setPath(TreeFolderItem node, string path) {
	    	TreeFolderItem newNode = new TreeFolderItem(node, SWT.NULL);
			newNode.addPath(path);
			return newNode;
		}
		void addPath(string path) {
			fullPath = path;
			setText(path[std.string.lastIndexOf(path, "\\") + 1  .. $]);
		}
		void addPath(TreeFolderItem node, string path) {
			TreeFolderItem rootNode = setPath(node, path);
			string[] fnode = scanDirs(path);
			if (fnode.length) {
				// In Directory
				foreach (i; 0 .. fnode.length) {
				//  recursive mode
				//	addPath(rootNode, fnode[i]);
					setPath(rootNode, fnode[i]);
				}
			}
		}
		string[] scanDirs(string nextDirs) {
			string[] fnode;
			try {
				foreach (DirEntry f; dirEntries(nextDirs, SpanMode.shallow)) {
					if (f.isDir()) {
						fnode ~= f.name;
					}
				}
			}
			catch (Exception ex) {
			}
			return fnode;
		}
	}
//-----------------------------------------
	enum BUTTON_WIDTH = 70;
	enum HORIZONTAL_SPACING = 3;
	enum MARGIN_WIDTH = 0;
	enum MARGIN_HEIGHT = 2;
    Label createHorizotalLine(Composite c)
    {
        Label line = new Label(c, SWT.SEPARATOR | SWT.HORIZONTAL);
        GridData data = new GridData(GridData.HORIZONTAL_ALIGN_FILL);
        line.setLayoutData(data);
        return line;
    }
	
    Composite createRightAlignmentComposite()
    {
        Composite c = new Composite(shell, SWT.NONE);
        GridLayout layout = new GridLayout(2, false);
        layout.horizontalSpacing = HORIZONTAL_SPACING;
        layout.marginWidth = MARGIN_WIDTH;
        layout.marginHeight = MARGIN_HEIGHT;
        c.setLayout(layout);
        GridData data = new GridData(GridData.HORIZONTAL_ALIGN_END);
        c.setLayoutData(data);
        return c;
    }
	
	Button createButton(Composite c, int style, string name, int minWidth)
	{
		Button b = new Button(c, style);
		b.setText(name);
		
		GridData d = new GridData();
		int w = b.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
		if (w < minWidth) {
			d.widthHint = minWidth;
		} else {
			d.widthHint = w;
		}
		b.setLayoutData(d);
    	return b;
	}
	
	Label createLabel(Composite c, string text, int style = SWT.NONE) {
		Label l = new Label(c, style);
		l.setText(text);
		return l;
	}
}

