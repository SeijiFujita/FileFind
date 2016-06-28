// Written in the D programming language.
/*
 * dmd 2.070.0 - 
 *
 * Copyright Seiji Fujita 2016.
 * Distributed under the Boost Software License, Version 1.0.
 * http://www.boost.org/LICENSE_1_0.txt
 */

// http://www.java2s.com/Code/Java/SWT-JFace-Eclipse/CatalogSWT-JFace-Eclipse.htm
// http://www.java2s.com/Code/JavaAPI/org.eclipse.swt.widgets/Catalogorg.eclipse.swt.widgets.htm
// http://study-swt.info/

import org.eclipse.swt.all;
import java.lang.all;

import std.conv;
import std.file;
import std.path;
import std.format;
import std.string;

import rfind;
import SelectDirectoryDialog;
import dlsbuffer;


class MainForm
{
	Display		display;
	Shell   	shell;
	Text		outputText;
	Label		statusLine;
	Combo		regexBox;
	Combo		dirBox;
	Button		runbtn;
	Button 		fullPath;
	Find		reff;
	
	this() {
		auto mgr = new WindowManager("Find file.");
		display = mgr.getDisplay();
		shell = mgr.getShell();
		reff = new Find(&puts);
		setMenu();
		createComponents();
		mgr.run();
	}
	
	private void puts(string s) {
		display.syncExec(new class Runnable {
			void run() {
				if (outputText.isDisposed()) {
					return;
				}
				outputText.append(s ~ outputText.getLineDelimiter());
			}
		});
	}
	
	void findThread() {
		string dir = dirBox.getText();
		if (dir.length > 0 && dir.exists() && dir.isDir()) {
			outputText.setText("");
			statusLine.setText("[ Running.. ]");
			string regex = regexBox.getText();
			bool   fpath = fullPath.getSelection();
			
			void exec() {
				Thread thread = new Thread({
					// thread 内からUI操作を行う場合は
					// display.syncExe/asyncExe から行わないと
					// UI のインスタンスが得られないで即死する
					if (display.isDisposed()) {
						return;
					}
					reff.findfile(dir, regex, fpath);
					ulong count = reff.matchCount();
					ulong files = reff.fileCount();
					string starttime = reff.StartTime();
					string stoptime = reff.StopTime();
					
					display.syncExec(new class Runnable {
						void run() {
							if (statusLine.isDisposed()) {
								return;
							}
							statusLine.setText(format("[ %d ]", count));
							string tmsg = reff.getStop() ? "#- Find STOP opration!" : "#- Find done...";
							outputText.append(
								tmsg ~ outputText.getLineDelimiter()
								~ "# Start :" ~ starttime ~ outputText.getLineDelimiter()
								~ "# Stop  :" ~ stoptime  ~ outputText.getLineDelimiter()
								~ "# Files/Match :" ~ to!string(files) ~ "/" ~ to!string(count) ~ " files" ~ outputText.getLineDelimiter()
							);
							// runbtn.setEnabled(true);
							runbtn.setText("Start");
						}
					});
				}); // Thread
				thread.start();
			} // exec
			display.asyncExec(dgRunnable(&exec));
		}
		else {
			outputText.setText("#directory missmatch!");
			// dirBox.setText(getSearchPath());
			// runbtn.setEnabled(true);
			runbtn.setText("Start");
		}
	}
	
	Composite createComposit(int col, int layout) {
		// container Composite
		Composite container = new Composite(shell, SWT.NONE);
		container.setLayoutData(new GridData(layout));
		container.setLayout(new GridLayout(col, false));
		return container;
	}
	
	string[] regexList;
	bool searchRegexList(string s) {
		foreach (v; regexList) {
			if (v == s) {
				return true;
			}
		}
		return false;
	}
	
	string[] dirList;
	bool searchDirList(string s) {
		foreach (v; dirList) {
			if (v == s) {
				return true;
			}
		}
		return false;
	}
	
	void addList() {
		
		string s = regexBox.getText();
		if (!searchRegexList(s)) {
			regexList ~= s;
			regexBox.setItems(regexList);
			regexBox.setText(s);
		}
		s = dirBox.getText();
		if (!searchDirList(s)) {
			dirList ~= s;
			dirBox.setItems(dirList);
			dirBox.setText(s);
		}
	}
	
	void createComponents() {
		// shell layout
		shell.setLayout(new GridLayout(1, false));
		// container Composite
		Composite container = createComposit(4, GridData.FILL_HORIZONTAL);
		
		//
		createLabel(container, "RegEx:");
		GridData layoutData = new GridData(GridData.FILL_HORIZONTAL);
		regexBox = new Combo(container, SWT.DROP_DOWN | SWT.BORDER);
		regexBox.setLayoutData(layoutData);
		
		runbtn = createButton(container, "Start");
		void onSelection_runbtn(SelectionEvent e) {
			addList();
			if (reff.getStatus()) {
				reff.Stop();
			} else {
				runbtn.setText("STOP");
				findThread();
			}
		}
		runbtn.addSelectionListener(
		    dgSelectionListener(SelectionListener.SELECTION, &onSelection_runbtn)
		);
		// full path check box
		fullPath = createButton(container, "FullPath", SWT.CHECK);
		
		//
		createLabel(container, "Dir:");
		layoutData = new GridData(GridData.FILL_HORIZONTAL);
		dirBox = new Combo(container, SWT.DROP_DOWN | SWT.BORDER);
		dirBox.setLayoutData(layoutData);
		dirBox.setText(getSearchPath());
		Button dirbtn = createButton(container, "Dir");
		void onSelection_dirbtn(SelectionEvent e) {
			auto ddlg = new SelectDirectoryDialog(shell);
			string d = ddlg.open(dirBox.getText());
			if (d !is null) {
				dirBox.setText(d);
			}
		}
		dirbtn.addSelectionListener(
			dgSelectionListener(SelectionListener.SELECTION, &onSelection_dirbtn)
		);
		//
		createText();
		//
		setStatusLine();
	}
	
	string getSearchPath() {
		import core.runtime: Runtime;
		string result;
		if (Runtime.args.length >= 2) {
			result = Runtime.args[1].dup;
		} else {
			result = getcwd();
		}
		return result;
	}
	
	void setStatusLine() {
		statusLine = new Label(shell,  SWT.BORDER /+ SWT.NONE +/);
		statusLine.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false));
	}
	
	void createText() {
		outputText = new Text(shell, SWT.MULTI | SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL);
		GridData layoutData = new GridData(GridData.FILL_BOTH);
		outputText.setLayoutData(layoutData);
		Listener scrollBarListener = new class Listener {
			override void handleEvent(Event event) {
				Text t = cast(Text)event.widget;
				Rectangle r1 = t.getClientArea();
				Rectangle r2 = t.computeTrim(r1.x, r1.y, r1.width, r1.height);
				Point p = t.computeSize(SWT.DEFAULT,  SWT.DEFAULT,  true);
				t.getHorizontalBar().setVisible(r2.width <= p.x);
				t.getVerticalBar().setVisible(r2.height <= p.y);
				if (event.type == SWT.Modify) {
					t.getParent().layout(true);
					t.showSelection();
				}
			}
		};
		outputText.addListener(SWT.Resize, scrollBarListener);
		outputText.addListener(SWT.Modify, scrollBarListener);
		setDragDrop(outputText);
	}
	
// https://github.com/d-widget-toolkit/base/blob/master/src/java/lang/wrappers.d
// stringcast()
// stringArrayFromObject()
//
	void setDragDrop(Text tt) {
		int operations = DND.DROP_MOVE | DND.DROP_COPY | DND.DROP_LINK;
		
		DragSource source = new DragSource(tt, operations);
		source.setTransfer([TextTransfer.getInstance()]);
		source.addDragListener(new class DragSourceListener {
			override void dragStart(DragSourceEvent event) {
				event.doit = (tt.getSelectionCount() != 0);
			}
			override void dragSetData(DragSourceEvent event) {
				//	event.data = new ArrayWrapperString(tt.getSelectionText());
				event.data = stringcast(tt.getSelectionText());
			}
			override void dragFinished(DragSourceEvent event) {
				if (event.detail == DND.DROP_MOVE) {
					// ;
				}
			}
		});
		DropTarget target = new DropTarget(tt, operations);
		target.setTransfer([TextTransfer.getInstance(), FileTransfer.getInstance()]);
		target.addDropListener(new class DropTargetAdapter {
			override void dragEnter(DropTargetEvent event) {
				// ドラッグ中のカーソルが入ってきた時の処理
				// 修飾キーを押さない場合のドラッグ＆ドロップはコピー
				//if (event.detail == DND.DROP_DEFAULT)
				//	event.detail = DND.DROP_COPY;
				dragOperationChanged(event);
			}
			override void dragOperationChanged(DropTargetEvent event) {
				// ドラッグ中に修飾キーが押されて処理が変更された時の処理
				// 修飾キーを押さない場合のドラッグ＆ドロップはコピー
				event.detail = DND.DROP_NONE;
				if (TextTransfer.getInstance().isSupportedType(event.currentDataType)) {
					event.detail = DND.DROP_COPY;
				} else if (FileTransfer.getInstance().isSupportedType(event.currentDataType)) {
					event.detail = DND.DROP_COPY;
				}
			}
			override void drop(DropTargetEvent event) {
				// event.data の内容を確認してカーソル位置にテキストをドロップ
				if (event.data is null) {
					event.detail = DND.DROP_NONE;
				} else if (TextTransfer.getInstance().isSupportedType(event.currentDataType)) {
					string st = stringcast(cast(Object)event.data);
					tt.insert(st);
				} else if (FileTransfer.getInstance().isSupportedType(event.currentDataType)) {
					string[] sar = stringArrayFromObject(event.data);
					foreach(v ; sar) {
						tt.insert(v ~ tt.getLineDelimiter());
					}
				}
			}
		});
	}
	Button createButton(Composite c, string text = "", int style = 0, int width = 0) {
		if (text is null) {
			text = "OK";
		}
		if (style == 0) {
			style = SWT.PUSH;
		}
		if (width == 0) {
			width = 80;
		}
		Button b = new Button(c, style);
		b.setText(text);

		GridData d = new GridData();
		int w = b.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
		if (w < width) {
			d.widthHint = width;
		} else {
			d.widthHint = w;
		}
		b.setLayoutData(d);
		return b;
	}

	Label createLabel(Composite c, string text, int style = 0) {
		if (style == 0) {
			style = SWT.NONE;
		}
		Label l = new Label(c, style);
		l.setText(text);
		return l;
	}

//----------------------
	void addSubMenu(Menu menu, string text, void delegate() dg, int accelerator = 0) {
		MenuItem item = new MenuItem(menu, SWT.PUSH);
		item.setText(text);
		if (accelerator != 0) {
			item.setAccelerator(accelerator); // SWT.CTRL + 'A'
		}
		item.addSelectionListener(new class SelectionAdapter {
                override void widgetSelected(SelectionEvent event) {
                    dg();
				}
			}
		);
		
/**		item.addArmListener(new class ArmListener {
				void widgetArmed(ArmEvent event) {
				//	statusLine.setText((cast(MenuItem)event.getSource()).getText());
				}
			}
		);
*/	}
    void addMenuSeparator(Menu menu) {
		new MenuItem(menu, SWT.SEPARATOR);
	}
	Menu addTopMenu(Menu bar, string text) {
		// menu top
		MenuItem menuItem = new MenuItem(bar, SWT.CASCADE);
		menuItem.setText(text);
		// menu 
		Menu menu = new Menu(bar);
		menuItem.setMenu(menu);
		return menu;
	}
	void setMenu() {
		// create menubar
		Menu bar = new Menu(shell, SWT.BAR);
		shell.setMenuBar(bar);
		// add files menu
		Menu fileMenu = addTopMenu(bar, "ファイル(&F)"); 
//		addSubMenu(fileMenu, "新規(&N)\tCtrl+N", &fileOpen, SWT.CTRL + 'N');
//		addSubMenu(fileMenu, "開く(&O)...\tCtrl+O", &dg_dummy, SWT.CTRL + 'O');
//		addSubMenu(fileMenu, "上書き保存(&S)\tCtrl+S", &dg_dummy, SWT.CTRL + 'S');
//		addSubMenu(fileMenu, "名前を付けて保存(&A)...", &dg_dummy);
//		addMenuSeparator(fileMenu);
		addSubMenu(fileMenu, "終了(&X)", &dg_exit);
		// add ...
		Menu setupMenu = addTopMenu(bar, "設定(&S)"); 
//		addSubMenu(setupMenu, "FontDialog", &selectFont);
//		addSubMenu(setupMenu, "ColorDialog", &selectColor);
//		addMenuSeparator(setupMenu);
		addSubMenu(setupMenu, "About", &dg_dummy);
	}
/**	
	struct SubMenuData {
		string name;
		void delegate() dg;
		int accelerator;
		
		addSubMenu(string m, void delegate() d, int acc);
		
	}
	struct MenuData {
		string name;
		SubMenuData[] submenu;
	}
*/	
//----------------------
    void dg_dummy() {
	}
	void dg_exit() {
		shell.close();
	}
	void fileOpen() {
		FileDialog dialog = new FileDialog(shell, SWT.OPEN);
		dialog.setFilterExtensions(["*.d", "*.java", "*.*"]);
		string fname = dialog.open();
		if (fname.length != 0) {
		}
    	
    }
	void selectFont() {
		FontDialog fontDialog = new FontDialog(shell);
		// set current FontSet
		// fontDialog.setFontList(text.getFont().getFontData());
		FontData fontData = fontDialog.open();
		if (fontData !is null){
			// if (font !is null)
			//	font.dispose();
			// font = new Font(display, fontData);
			// text.setFont(font);
		}
	}
	void selectColor() {
		ColorDialog colorDialog = new ColorDialog(shell);
//		colorDialog.setRGB(text.getForeground().getRGB());
		RGB rgb = colorDialog.open();
//		if (rgb !is null) {
//			if (foregroundColor !is null) {
//				foregroundColor.dispose();
//			}
//			foregroundColor = new Color(display, rgb);
//			text.setForeground(foregroundColor);
//		}
	}
	string selectDirecoty(string setpath) {
		DirectoryDialog ddlg = new DirectoryDialog(shell);
		ddlg.setFilterPath(setpath);
		ddlg.setText("DirectoryDialog");
		ddlg.setMessage("Select a directory");
		return ddlg.open();
	}
}
//-----------------------------------------------------------------------------
void main()
{
	try {
		dlog("# start");
		import core.runtime: Runtime;
		string arg;
		if (Runtime.args.length >= 2) {
			arg = Runtime.args[1];
		}
		auto main = new MainForm();
	} catch(Exception e) {
		dlog("Exception: ", e.toString());
		// MessageBox.showInfo(e.toString(), "Exception!");
	}
}
//-----------------------------------------------------------------------------
class WindowManager
{
private:
	Display display;
	Shell   shell;
	Label   statusLine;

	void init() {
		if (display is null) {
			display = new Display();
		}
		shell = new Shell(display);
	}

public:
	this() {
		init();
	}
	this(string title) {
		init();
		window(title);
	}
	void window(string title, uint width = 600, uint hight = 400) {
		// create window
		shell.setText(title);
		shell.setSize(width, hight);
		shell.setLayout(new GridLayout(1, false));
	}
	Display getDisplay() {
		return display;
	}
	Shell getShell() {
		return shell;
	}
	void setStatusLine() {
		statusLine = new Label(shell,  SWT.BORDER /+ SWT.NONE +/);
		statusLine.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false));
	}
	void run() {
		// shell.pack();
		shell.open();
		while(!shell.isDisposed()) {
			if (!display.readAndDispatch()) {
				display.sleep();
			}
		}
		display.dispose();
	}
	
	// SWT.COLOR_DARK_GRAY;
	Color getSystemColor(int id) {
		return display.getSystemColor(id);
	}
	Color getColor(int red, int green, int blue) {
		int rgb = (red & 0xFF) | ((green & 0xFF) << 8) | ((blue & 0xFF) << 16);
		return Color.win32_new(display, rgb);
	}
}

