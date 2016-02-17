//
//  SecondCollectionViewController.swift
//  豆瓣美女
//
//  Created by lu on 15/12/3.
//  Copyright © 2015年 lu. All rights reserved.
//

import Foundation

//
//  MainCollectionViewController.swift
//  豆瓣美女
//
//  Created by lu on 15/11/12.
//  Copyright © 2015年 lu. All rights reserved.
//

import UIKit
import Foundation
import UIKit
import Alamofire
import Kanna
import JGProgressHUD
import SDWebImage

private let reuseIdentifier = "Cell"

class MainCollectionController: UICollectionViewController, UICollectionViewDelegateFlowLayout, TopMenuDelegate{
    
    var photos                = NSMutableOrderedSet()//缩略图
    var photosBig             = NSMutableOrderedSet()//大图

    var populatingPhotos      = false//是否在获取图片
    var currentPage           = 1//当前页数
    var isGot                 = false//标志是否已经获取到数据
    var menuView:ZNTopMenuView! //滑动菜单
    var currentType: PageType = .daxiong//当前页面类型
    
    //MARK: - UI初始化
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //让界面显示1秒
        //        NSThread.sleepForTimeInterval(0.5)
        configureRefresh()
        
        //初始化滑动栏
        initTop()

        //设置视图
        setupView()
        
        //添加所有的按钮
        addBarItem()
        
        //获取第一页图片
        populatePhotos()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
    }
    
    func getPageUrl()-> String{
        return pageBaseUrl + currentType.rawValue + "&pager_offset=" + "\(currentPage)"
    }
    /*!
    case daxiong = "2"
    case qiaotun = "6"
    case heisi   = "7"
    case meitui  = "3"
    case yanzhi  = "4"
    case dazahui = "5"
    */
    //MARK: 设置滑动菜单
    func initTop(){
        let navBarHeight = self.navigationController?.navigationBar.frame.height ?? 0.0
        
        //设置menu的高度和位置，在navigationbar下面
        let menuView = ZNTopMenuView(frame: CGRectMake(0, navBarHeight + topViewHeight - 10, kScreenSize.width, topViewHeight))
        /*!
        设置滑动菜单的背景颜色和下划线颜色
        */
        menuView.bgColor = UIColor.whiteColor()
        menuView.lineColor = UIColor.grayColor()
        menuView.delegate = self
        //设置显示的类别
        menuView.titles = ["大胸妹", "小翘臀", "黑丝袜", "美腿控", "有颜值", "大杂烩"]

        
        //关闭scrolltotop，不然点击status bar不会返回第一页
        menuView.setScrollToTop(false)
        self.menuView = menuView
        self.view.addSubview(menuView)
    }
    
    //MARK: TopMenuDelegate 代理方法，点击触发
    func topMenuDidChangedToIndex(index:Int){
        self.navigationItem.title = self.menuView.titles[index] as String
        
        currentType = PhotoUtil.selectTypeByNumber(index)
        
        photos.removeAllObjects()
        photosBig.removeAllObjects()
        //清除所有图片，设置为第一页，刷新数据
        self.currentPage = 1
        
        self.collectionView?.reloadData()
        
        populatePhotos()//开始获取图片url，由于不是自己搭建的服务器，所以只能抓取HTML进行解析
    }
    
    //MARK: 上拉下拉刷新
    func configureRefresh(){
        self.collectionView?.header = MJRefreshNormalHeader(refreshingBlock: { () in
            print("header")
            self.handleRefresh()
            self.collectionView?.header.endRefreshing()
        })
        
        self.collectionView?.footer = MJRefreshAutoFooter(refreshingBlock:
            { () in
                print("footer")
                self.populatePhotos()
                self.collectionView?.footer.endRefreshing()
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.toolbarHidden = true
    }
    
    func setupView() {
        //设置标题和颜色
        self.navigationItem.title = "豆瓣美女"
        self.view.backgroundColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.barTintColor = UIColor.naviColor()
        self.collectionView?.backgroundColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        self.collectionView?.scrollsToTop = true
        
        //设置UICollectionViewFlowLayout
        self.collectionView?.frame = self.view.frame
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (view.bounds.size.width - 30)/2, height: ((view.bounds.size.width - 30)/2)/225.0*300.0)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10

        collectionView!.collectionViewLayout = layout
        self.collectionView!.registerClass(MainCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    //添加navigationitem
    func addBarItem(){
        let item = UIBarButtonItem(image: UIImage(named: "Del"), style: UIBarButtonItemStyle.Plain, target: self, action: "setting:")
        item.tintColor = UIColor.whiteColor()
        
        self.navigationItem.rightBarButtonItem = item
    }
    
    @IBAction func setting(sender: AnyObject){
        let alert = UIAlertController(title: "提示", message: "确认要清除图片缓存么?", preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.Default, handler: clearCache)
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //清除缓存
    func clearCache(alert: UIAlertAction!){
        
        print("clear")
        let size = SDImageCache.sharedImageCache().getSize() / 1000 //KB
        var string: String
        if size/1000 >= 1{
            string = "清除缓存 \(size/1000)M"
        }else{
            string = "清除缓存 \(size)K"
        }
        let hud = JGProgressHUD(style: JGProgressHUDStyle.Light)
        hud.textLabel.text = string
        hud.indicatorView = JGProgressHUDSuccessIndicatorView()
        hud.showInView(self.view, animated: true)
        SDImageCache.sharedImageCache().clearDisk()
        hud.dismissAfterDelay(1.0, animated: true)
    }
    
    override func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        return true
    }
    
    //MARK:- 获取图片url逻辑
    func handleRefresh() {
        photos.removeAllObjects()
        //        清除所有图片，设置为第一页，刷新数据
        self.currentPage = 1
        self.collectionView?.reloadData()
        
        populatePhotos()//开始获取图片
    }
    
    //转换图片url
    func transformUrl(urls: [String]){
        for url in urls{
            let urlBig = url.stringByReplacingOccurrencesOfString("bmiddle", withString: "large")
            print(urlBig)
            photosBig.addObject(urlBig)
        }
    }
    
    //获取图片
    func populatePhotos(){
        if populatingPhotos{//正在获取，则返回
            print("return back")
            return
        }
        
        //标记正在获取，其他线程获取则返回
        populatingPhotos = true
        let pageUrl = getPageUrl()
        Alamofire.request(.GET, pageUrl).validate().responseString{
            (request, response, result) in
            
            //
            let isSuccess = result.isSuccess
            let html = result.value
            let HUD = JGProgressHUD(style: JGProgressHUDStyle.Light)
            
            if isSuccess == true{
                //设置等待菊花
                HUD.textLabel.text = "加载中"
                HUD.showInView(self.view, animated: true)
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                    //用photos保存临时数据
                    var urls = [String]()
                    //用kanna解析html数据
                    if let doc = Kanna.HTML(html: html!, encoding: NSUTF8StringEncoding){
                        CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingASCII)
                        let lastItem = self.photos.count
                        //解析imageurl
                        for node in doc.css("img"){
                            urls.append(node["src"]!)
                            self.isGot = true
                        }
                        
                        //怕没有获取到数据，做了个保护
                        if self.isGot{
                            self.photos.addObjectsFromArray(urls)
                            self.transformUrl(urls)
                        }
                        
                        //只刷新增加的数据，不能用reloadData，会造成闪屏
                        let indexPaths = (lastItem..<self.photos.count).map { NSIndexPath(forItem: $0, inSection: 0) }
                        dispatch_async(dispatch_get_main_queue()) {
                            self.collectionView!.insertItemsAtIndexPaths(indexPaths)
                        }
                        if self.isGot{
                            self.currentPage++
                            self.isGot = false
                        }
                    }
                }
            }else{
                HUD.textLabel.text = "网络有问题，请检查网络"
                HUD.indicatorView = JGProgressHUDErrorIndicatorView()
                HUD.showInView(self.view, animated: true)
                HUD.dismissAfterDelay(1.0, animated: true)
            }
            
            //清除HUD
            HUD.dismiss()
            self.populatingPhotos = false
        }
    }
    
    //MARK: - scrollView
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        print(offset)
        var alpha: CGFloat
        if offset >= HIDEOFFSET{
            alpha = 0
        }else{
            alpha = PhotoUtil.MIN(1, two: (HIDEOFFSET - offset)/HIDEOFFSET)
        }
        navigationController?.navigationBar.alpha = alpha
        menuView.alpha = alpha
    }

    //MARK: - CollectionView
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.view.frame.width, height: topViewHeight)
    }
    
    //设置四周边距
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10.0, 10.0, 0.0, 10.0)
    }
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.collectionView?.footer.hidden = self.photos.count == 0
        return self.photos.count
    }
    
    //点击查看大图
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        var browser:PhotoBrowserView
        
        //网路数据源
        browser = PhotoBrowserView.initWithPhotos(withUrlArray: self.photosBig.array)
        //类型为网络
        browser.sourceType = SourceType.REMOTE
        
        //设置展示哪张图片
        browser.index = indexPath.row
        
        //显示
        browser.show()
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! MainCollectionViewCell
        
        //设置圆角和阴影
        cell.imageView.layer.cornerRadius = 15.0
        cell.imageView.layer.masksToBounds = true
        cell.layer.shadowColor = UIColor.darkGrayColor().CGColor
        cell.layer.shadowOffset = CGSizeMake(2, 2)
        cell.layer.shadowRadius = 4.0
        cell.layer.shadowOpacity = 0.9
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 15.0).CGPath

        let imageURL = NSURL(string: (photos.objectAtIndex(indexPath.row) as! String))
        //复用时先置为nil，使其不显示原有图片
        cell.imageView.image = nil
        //用sdwebimage更加的方便，集成了cache，弃用原来的。。
        cell.imageView.sd_setImageWithURL(imageURL)
        
        return cell
    }
}
