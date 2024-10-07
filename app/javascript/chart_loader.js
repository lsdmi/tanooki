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
    colors: ['#00BFFF', '#009999', '#FF1493', '#FF6B6B'],
    chart: {
      height: 200,
      type: 'donut',
      background: 'transparent',
    },
    plotOptions: {
      pie: {
        donut: {
          labels: {
            show: true,
            name: {
              show: true,
              fontFamily: 'Oswald, sans-serif',
              fontWeight: 600,
              color: '#FFFFFF',
              offsetY: 20,
            },
            total: {
              showAlways: true,
              show: true,
              label: 'закладинок',
              fontFamily: 'Oswald, sans-serif',
              fontWeight: 600,
              color: '#FFFFFF',
            },
            value: {
              show: true,
              fontFamily: 'Oswald, sans-serif',
              fontWeight: 600,
              color: '#FFFFFF',
              offsetY: -20,
              formatter: function (value) {
                return value
              },
            },
          },
          size: '75%',
        },
      },
    },
    labels: ['Читають', 'Прочитано', 'Відкладено', 'Покинуто'],
    dataLabels: {
      enabled: false,
    },
    legend: {
      position: 'bottom',
      fontFamily: 'Oswald, sans-serif',
      fontWeight: 500,
      labels: {
        colors: '#FFFFFF',
      },
      markers: {
        width: 12,
        height: 12,
        strokeWidth: 0,
        strokeColor: '#001F3F',
        radius: 12,
      },
    },
    stroke: {
      width: 2,
      colors: ['#001F3F'],
    },
    theme: {
      mode: 'dark',
    },
    tooltip: {
      theme: 'dark',
      style: {
        fontSize: '14px',
        fontFamily: 'Oswald, sans-serif',
      },
    },
  }
}

// The rest of your code remains the same
document.addEventListener('turbo:load', initializeChart)
