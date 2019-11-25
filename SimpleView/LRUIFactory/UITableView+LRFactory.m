//
//  UITableView+LRFactory.m
//  SimpleView
//
//  Created by leo on 2019/11/23.
//  Copyright © 2019 ileo. All rights reserved.
//

#import "UITableView+LRFactory.h"
#import "NSObject+LRFactory.h"
#import <objc/runtime.h>

#define kLrfCellID @"kLrfCellID"
#define kLrfCellHeight @"kLrfCellHeight"
#define kLrfCellInfo @"kLrfCellInfo"

#define kLrfCells @"kLrfCells"

#define kLrfSectionInfo @"kLrfSectionInfo"
#define kLrfHeaderHeight @"kLrfHeaderHeight"
#define kLrfFooterHeight @"kLrfFooterHeight"
#define kLrfHeaderID @"kLrfHeaderID"
#define kLrfFooterID @"kLrfFooterID"

@interface UITableView () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation UITableView (LRFactory)

- (LRFCellInfo *)lrf_cellInfoWithCellID:(NSString *)cellID height:(CGFloat)height info:(NSDictionary *)info{
    if (!cellID) {
        cellID = @"cell";
    }
    if (!height) {
        height = 0;
    }
    if (!info) {
        info = @{};
    }
    return @{
        kLrfCellID: cellID,
        kLrfCellHeight: @(height),
        kLrfCellInfo: info
    };
}

- (LRFSectionInfo *)lrf_sectionInfoWithCells:(NSArray<LRFCellInfo *> *)cells{
    return [self lrf_sectionInfoWithCells:cells info:@{} headerFooterInfo:[self lrf_headerInfoWithHeaderID:@"header" height:0]];
}

- (LRFSectionInfo *)lrf_sectionInfoWithCells:(NSArray<LRFCellInfo *> *)cells info:(NSDictionary *)info headerFooterInfo:(LRFHeaderFooterInfo *)headerFooterInfo{
    if (!cells) {
        cells = @[];
    }
    if (!info) {
        info = @{};
    }
    if (!headerFooterInfo) {
        headerFooterInfo = @{};
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:headerFooterInfo];
    [dic addEntriesFromDictionary:@{
        kLrfCells: cells,
        kLrfSectionInfo: info
    }];
    return [dic copy];
}

- (LRFHeaderFooterInfo *)lrf_headerInfoWithHeaderID:(NSString *)headerID height:(CGFloat)height{
    return [self lrf_headerFooterInfoWithHeaderID:headerID headerHeight:height footerID:@"footer" footerHeight:0];
}

- (LRFHeaderFooterInfo *)lrf_footerInfoWithFooterID:(NSString *)footerID height:(CGFloat)height{
    return [self lrf_headerFooterInfoWithHeaderID:@"header" headerHeight:0 footerID:footerID footerHeight:height];
}

- (LRFHeaderFooterInfo *)lrf_headerFooterInfoWithHeaderID:(NSString *)headerID headerHeight:(CGFloat)headerHeight footerID:(NSString *)footerID footerHeight:(CGFloat)footerHeight{
    if (!headerID) {
        headerID = @"header";
    }
    if (!footerID) {
        footerID = @"footer";
    }
    if (!headerHeight) {
        headerHeight = 0;
    }
    if (!footerHeight) {
        footerHeight = 0;
    }
    return @{
        kLrfHeaderHeight: @(headerHeight),
        kLrfFooterHeight: @(footerHeight),
        kLrfHeaderID: headerID,
        kLrfFooterID: footerID
    };
}

- (CGFloat)lrf_contentHeight{
    CGFloat height = 0;
    if (self.lrf_dataSource) {
        NSArray<LRFSectionInfo *> *sections = [self.lrf_dataSource lrf_dataSourcesWithTableView:self];
        if (sections) {
            for (LRFSectionInfo *section in sections) {
                CGFloat headerHeight = [section[kLrfHeaderHeight] floatValue];
                CGFloat footerHeight = [section[kLrfFooterHeight] floatValue];
                height += (headerHeight + footerHeight);
                NSArray<LRFCellInfo *> *cells = section[kLrfCells];
                for (LRFCellInfo *cell in cells) {
                    CGFloat h = [cell[kLrfCellHeight] floatValue];
                    height += h;
                }
            }
        }
    }
    return height;
}


# pragma mark - delegate

static char klrf_delegate;

- (id)lrf_delegate{
    return objc_getAssociatedObject(self, &klrf_delegate);
}

- (void)setLrf_delegate:(id)lrf_delegate{
    self.delegate = self;
    objc_setAssociatedObject(self, &klrf_delegate, lrf_delegate, OBJC_ASSOCIATION_ASSIGN);
}

- (CGFloat)lrf_tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.lrf_dataSource) {
        NSArray<LRFSectionInfo *> *sections = [self.lrf_dataSource lrf_dataSourcesWithTableView:tableView];
        if (sections && sections.count > indexPath.section) {
            NSArray<LRFCellInfo *> *cells = sections[indexPath.section][kLrfCells];
            if (cells && cells.count > indexPath.row) {
                NSNumber *height = cells[indexPath.row][kLrfCellHeight];
                return [height floatValue];
            }
        }
    }
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [self lrf_tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)lrf_tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.lrf_dataSource) {
        NSArray<LRFSectionInfo *> *sections = [self.lrf_dataSource lrf_dataSourcesWithTableView:tableView];
        if (sections && sections.count > indexPath.section) {
            NSArray<LRFCellInfo *> *cells = sections[indexPath.section][kLrfCells];
            if (cells && cells.count > indexPath.row) {
                LRFCellInfo *cell = cells[indexPath.row];
                [self.lrf_dataSource lrf_tableView:tableView didSelectCellWithInfo:cell[kLrfCellInfo] cellID:cell[kLrfCellID]];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self lrf_tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (UIView *)lrf_tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (self.lrf_dataSource && [self.lrf_dataSource respondsToSelector:@selector(lrf_tableView:viewForHeaderWithInfo:headerFooterID:)]) {
        NSArray<LRFSectionInfo *> *sections = [self.lrf_dataSource lrf_dataSourcesWithTableView:tableView];
        if (sections && sections.count > section) {
            LRFSectionInfo *info = sections[section];
            return [self.lrf_dataSource lrf_tableView:tableView viewForHeaderWithInfo:info[kLrfSectionInfo] headerFooterID:info[kLrfHeaderID]];
        }
    }
    return [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"header"];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return [self lrf_tableView:tableView viewForHeaderInSection:section];
}

- (UIView *)lrf_tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (self.lrf_dataSource && [self.lrf_dataSource respondsToSelector:@selector(lrf_tableView:viewForFooterWithInfo:headerFooterID:)]) {
        NSArray<LRFSectionInfo *> *sections = [self.lrf_dataSource lrf_dataSourcesWithTableView:tableView];
        if (sections && sections.count > section) {
            LRFSectionInfo *info = sections[section];
            return [self.lrf_dataSource lrf_tableView:tableView viewForFooterWithInfo:info[kLrfSectionInfo] headerFooterID:info[kLrfFooterID]];
        }
    }
    return [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"footer"];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return [self lrf_tableView:tableView viewForFooterInSection:section];
}

-(CGFloat)lrf_tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (self.lrf_dataSource) {
        NSArray<LRFSectionInfo *> *sections = [self.lrf_dataSource lrf_dataSourcesWithTableView:tableView];
        if (sections && sections.count > section) {
            LRFSectionInfo *info = sections[section];
            NSNumber *height = info[kLrfHeaderHeight];
            if (height) {
                return [height floatValue];
            }
        }
    }
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return [self lrf_tableView:tableView heightForHeaderInSection:section];
}

-(CGFloat)lrf_tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (self.lrf_dataSource) {
        NSArray<LRFSectionInfo *> *sections = [self.lrf_dataSource lrf_dataSourcesWithTableView:tableView];
        if (sections && sections.count > section) {
            LRFSectionInfo *info = sections[section];
            NSNumber *height = info[kLrfFooterHeight];
            if (height) {
                return [height floatValue];
            }
        }
    }
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return [self lrf_tableView:tableView heightForFooterInSection:section];
}

# pragma mark - datasource

static char klrf_dataSource;

- (id<LRF_UITableViewDataSource>)lrf_dataSource{
    return objc_getAssociatedObject(self, &klrf_dataSource);
}

- (void)setLrf_dataSource:(id<LRF_UITableViewDataSource>)lrf_dataSource{
    self.dataSource = self;
    objc_setAssociatedObject(self, &klrf_dataSource, lrf_dataSource, OBJC_ASSOCIATION_ASSIGN);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (self.lrf_dataSource) {
        NSArray<LRFSectionInfo *> *sections = [self.lrf_dataSource lrf_dataSourcesWithTableView:tableView];
        if (sections) {
            return sections.count;
        }
    }
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.lrf_dataSource) {
        NSArray<LRFSectionInfo *> *sections = [self.lrf_dataSource lrf_dataSourcesWithTableView:tableView];
        if (sections && sections.count > section) {
            NSArray<LRFCellInfo *> *cells = sections[section][kLrfCells];
            return cells.count;
        }
    }
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.lrf_dataSource) {
        NSArray<LRFSectionInfo *> *sections = [self.lrf_dataSource lrf_dataSourcesWithTableView:tableView];
        if (sections && sections.count > indexPath.section) {
            NSArray<LRFCellInfo *> *cells = sections[indexPath.section][kLrfCells];
            if (cells && cells.count > indexPath.row) {
                LRFCellInfo *cell = cells[indexPath.row];
                return [self.lrf_dataSource lrf_tableView:tableView cellWithInfo:cell[kLrfCellInfo] cellID:cell[kLrfCellID]];
            }
        }
    }
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
}

@end
