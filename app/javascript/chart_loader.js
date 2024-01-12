const initializeChart = () => {
  const donutChart = document.getElementById('donut-chart');

  if (donutChart && typeof ApexCharts !== 'undefined') {
    const chart = new ApexCharts(donutChart, getChartOptions());
    chart.render();
  }
}

const getChartOptions = () => {
  const stats = JSON.parse(document.getElementById('donut-chart').dataset.stats);

  return {
    series: stats,
    colors: ['#14b8a6', '#60a5fa', '#fb923c', '#fb7185'],
    chart: {
      height: 200,
      type: 'donut',
    },
    plotOptions: {
      pie: {
        donut: {
          labels: {
            show: true,
            name: {
              show: true,
              fontFamily: 'Oswald',
              offsetY: 20,
            },
            total: {
              showAlways: true,
              show: true,
              label: 'закладинок',
              fontFamily: 'Oswald'
            },
            value: {
              show: true,
              fontFamily: 'Oswald',
              offsetY: -20,
              formatter: function (value) {
                return value
              },
            },
          },
          size: '80%',
        },
      },
    },
    labels: ['Читають', 'Прочитано', 'Відкладено', 'Покинуто'],
    dataLabels: {
      enabled: false,
    },
    legend: {
      position: 'bottom',
      fontFamily: 'Oswald',
    }
  }
}

document.addEventListener('turbo:load', initializeChart);
