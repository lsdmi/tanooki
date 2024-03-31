function resizeGridItem(item, grid, rowHeight, rowGap) {
  const contentHeight = item.querySelector('.content').getBoundingClientRect().height;
  const rowSpan = Math.ceil((contentHeight + rowGap) / (rowHeight + rowGap));
  item.style.gridRowEnd = "span " + rowSpan;
}

function resizeAllGridItems(grid, rowHeight, rowGap) {
  const allItems = document.getElementsByClassName("comment-item");
  for (let x = 0; x < allItems.length; x++) {
    resizeGridItem(allItems[x], grid, rowHeight, rowGap);
  }
}

function initializeGrid() {
  const grid = document.getElementsByClassName("comments-grid")[0];
  const rowHeight = parseInt(window.getComputedStyle(grid).getPropertyValue('grid-auto-rows'));
  const rowGap = parseInt(window.getComputedStyle(grid).getPropertyValue('grid-row-gap'));

  resizeAllGridItems(grid, rowHeight, rowGap);

  window.addEventListener("resize", function () {
    resizeAllGridItems(grid, rowHeight, rowGap);
  });
}
