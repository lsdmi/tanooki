# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin 'flowbite', to: 'https://cdnjs.cloudflare.com/ajax/libs/flowbite/1.7.0/flowbite.turbo.min.js', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin '@rails/actiontext', to: 'actiontext.js'
pin 'slim-select', to: 'https://ga.jspm.io/npm:slim-select@2.5.0/dist/slimselect.es.js'
pin 'sweetalert2', to: 'https://ga.jspm.io/npm:sweetalert2@11.9.0/dist/sweetalert2.all.js'
