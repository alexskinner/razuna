module.exports = function(grunt) {

	// Project configuration.
	grunt.initConfig({
		pkg: grunt.file.readJSON('package.json'),
		clean: {
			contents: ['./global/dist/*', '!./global/dist/fonts', '!./global/dist/images'],
		},
		concat: {
			options: {
				separator: ';',
				nosort: true
			},
			vendors: {
				src: [
					'./global/js/jquery.validate.min.js',
					'./global/js/jquery.form.min.js',
					'./global/js/jquery-ui-1.12.1.custom/jquery-ui.min.js',
					'./global/videoplayer/js/flowplayer-3.2.6.min.js',
					'./global/js/AC_QuickTime.js',
					'./global/js/jstree/dist/jstree.min.js',
					'./global/js/tag/js/tag-it.js',
					'./global/js/notification/sticky.min.js',
					'./global/js/chosen/chosen.jquery.min.js',
					'./global/js/jquery.formparams.js',
					'./global/js/jquery.lazyload.min.js',
					'./global/js/jquery.scrollstop.js',
					'./global/js/masonry.pkgd.min.js',
					'./global/js/imagesloaded.pkgd.min.js',
					'./global/js/editor/js/froala_editor.pkgd.min.js',
					'./global/js/Magnific-Popup-1.1.0/dist/jquery.magnific-popup.min.js',
					'./global/js/noty-3.0.1/lib/noty.min.js'
				],
				dest: './global/dist/vendors_<%= pkg.script_version %>.js'
			},
			app: {
				src: [
					'./node_modules/popper.js/dist/umd/popper.js',
					'./node_modules/bootstrap/dist/js/bootstrap.js',
					'./global/host/dam/js/global.js',
				],
				dest: './global/dist/app_<%= pkg.script_version %>.js'
			},
			login: {
				src: [
					'./node_modules/popper.js/dist/umd/popper.js',
					'./node_modules/bootstrap/dist/js/bootstrap.js',
					'./global/js/jquery.validate.min.js',
					'./global/js/jquery.form.min.js',
					'./global/js/Magnific-Popup-1.1.0/dist/jquery.magnific-popup.min.js',
					'./global/host/dam/js/login.js',
				],
				dest: './global/dist/app_login_<%= pkg.script_version %>.js'
			},
			upload: {
				src: [
					'./global/js/plupload/plupload.full.js',
					'./global/js/plupload/jquery.plupload.queue/jquery.plupload.queue.js',
					'./global/js/jquery-ui-1.12.1.custom/jquery-ui.min.js',
				],
				dest: './global/dist/upload_<%= pkg.script_version %>.js'
			}
		},
		concat_css: {
			options: {
				options: {
					assetBaseUrl: 'fonts',
					baseDir: './global/dist/fonts',
				}
			},
			login_css: {
				src: [
					'./node_modules/bootstrap/dist/css/bootstrap.min.css',
					'./global/js/Magnific-Popup-1.1.0/dist/magnific-popup.css',
					'./global/host/dam/views/layouts/main.css'
				],
				dest: './global/dist/app_login_<%= pkg.script_version %>.css'
			},
			main_css: {
				src: [
					'./node_modules/bootstrap/dist/css/bootstrap.css',
					'./global/js/jquery-ui-1.12.1.custom/jquery-ui.min.css',
					'./global/js/jquery-ui-1.12.1.custom/jquery-ui.theme.min.css',
					'./global/stylesheets/font-awesome-4.7.0/css/font-awesome.min.css',
					'./global/videoplayer/css/multiple-instances.css',
					'./global/js/tag/css/jquery.tagit.css',
					'./global/host/dam/views/layouts/tagit.css',
					'./global/js/chosen/chosen.css',
					'./global/js/notification/sticky.min.css',
					'./global/js/editor/css/froala_editor.pkgd.min.css',
					'./global/js/editor/css/froala_style.min.css',
					'./global/js/Magnific-Popup-1.1.0/dist/magnific-popup.css',
					'./global/stylesheets/helpmonks-jstree-theme/style.css',
					'./global/js/noty-3.0.1/lib/noty.css',
					'./global/host/dam/views/layouts/main.css',
				],
				dest: './global/dist/app_<%= pkg.script_version %>.css'
			}
		},
		cssmin: {
			options: {
				sourceMap: true
			},
			target: {
				files: [
					// {
					// 	expand: true,
					// 	cwd: './public/stylesheets',
					// 	src: ['*.css', '!*.min.css', '!radio-checkbox.css', '!notes-theme.css', '!editor.css'],
					// 	dest: './public/dist',
					// 	ext: '.min.css'
					// },
					{
						src: './global/js/plupload/jquery.plupload.queue/css/jquery.plupload.queue.css',
						dest: './global/dist/upload_<%= pkg.script_version %>.min.css',
					},
					// {
					// 	src: './global/host/dam/views/layouts/main.css',
					// 	dest: './global/dist/main_<%= pkg.script_version %>.min.css',
					// },
					{
						expand: true,
						cwd: './global/dist',
						src: ['*.css', '!*.min.css'],
						dest: './global/dist',
						ext: '.min.css'
					}
				]
			}
		},
		replace: {
			fonts: {
				src: ['./global/dist/*.css'],
				overwrite: true,
				replacements: [
					{
						from: '../fonts/',
						to: 'fonts/'
					},
					{
						from: '../img/',
						to: 'images/'
					}
					// ,
					// {
					// 	from: /([0-9a-z\-\@]+.png)/img,
					// 	to: 'images/$1'
					// }
				]
			}
		},
		uglify: {
			options: {
				banner: '/*! <%= pkg.name %> <%= pkg.script_version %> <%= grunt.template.today("yyyy-mm-dd") %> */\n',
				compress: true,
				sourceMap: true,
				mangle: true
			},
			dist: {
				files: {
					'./global/dist/app_<%= pkg.script_version %>.min.js': ['<%= concat.app.dest %>'],
					'./global/dist/vendors_<%= pkg.script_version %>.min.js': ['<%= concat.vendors.dest %>'],
					'./global/dist/app_login_<%= pkg.script_version %>.min.js': ['<%= concat.login.dest %>'],
					'./global/dist/upload_<%= pkg.script_version %>.min.js': ['<%= concat.upload.dest %>'],
				}
			}
		},
		copy: {
			dist: {
				files: [
					{
						nonull: true,
						expand: true,
						cwd: './global/stylesheets/helpmonks-jstree-theme/fonts/',
						src: '**',
						dest: './global/dist/fonts'
					},
					{
						nonull: true,
						expand: true,
						cwd: './global/stylesheets/helpmonks-jstree-theme/images/',
						src: '**',
						dest: './global/dist/images'
					},
					{
						nonull: true,
						expand: true,
						cwd: './global/js/jquery-ui-1.12.1.custom/images/',
						src: '**',
						dest: './global/dist/images'
					},
					{
						nonull: true,
						expand: true,
						cwd: './global/host/dam/views/layouts/images/',
						src: '**',
						dest: './global/dist/images'
					},
					{
						nonull: true,
						expand: true,
						cwd: './global/js/plupload/jquery.ui.plupload/img',
						src: '**',
						dest: './global/dist/images'
					},
					{
						nonull: true,
						expand: true,
						cwd: './global/js/plupload/jquery.plupload.queue/img',
						src: '**',
						dest: './global/dist/images'
					},
					{
						nonull: true,
						expand: true,
						cwd: './global/js/chosen',
						src: '*.png',
						dest: './global/dist/images'
					},
					{
						nonull: true,
						expand: true,
						cwd: './global/stylesheets/font-awesome-4.7.0/fonts/',
						src: '*',
						dest: './global/dist/fonts/'
					},
				]
			},
			dev: {
				files: [
					{
						src: './global/js/app_login.js',
						dest: './global/dist/app_login_<%= pkg.script_version %>.min.js'
					},
					{
						src: './global/js/app_functions.js',
						dest: './global/dist/app_functions_<%= pkg.script_version %>.min.js'
					},
					{
						src: ['<%= concat.app.dest %>'],
						dest: './global/dist/app_<%= pkg.script_version %>.min.js'
					},
					{
						src: './global/js/loader_login.js',
						dest: './global/dist/loader_login_<%= pkg.script_version %>.min.js'
					},
					{
						src: './global/js/loader_main.js',
						dest: './global/dist/loader_main_<%= pkg.script_version %>.min.js'
					},
					{
						src: ['<%= concat.vendors.dest %>'],
						dest: './global/dist/vendors_<%= pkg.script_version %>.min.js'
					},
					{
						src: ['<%= concat.vendors_login.dest %>'],
						dest: './global/dist/vendors_login_<%= pkg.script_version %>.min.js'
					},
					{
						src: ['<%= concat.admin.dest %>'],
						dest: './global/dist/admin_<%= pkg.script_version %>.min.js'
					},
					{
						src: './global/js/loader_main_admin.js',
						dest: './global/dist/loader_main_admin_<%= pkg.script_version %>.min.js'
					},
					{
						src: ['<%= concat.vendors_admin.dest %>'],
						dest: './global/dist/vendors_admin_<%= pkg.script_version %>.min.js'
					},
					{
						src: ['<%= concat.editor.dest %>'],
						dest: './global/dist/editor_<%= pkg.script_version %>.min.js'
					}
				]
			}
		}
	});

	// Load the plugin that provides the "uglify" task.
	grunt.loadNpmTasks('grunt-contrib-uglify-es');
	grunt.loadNpmTasks('grunt-contrib-concat');
	grunt.loadNpmTasks('grunt-contrib-cssmin');
	grunt.loadNpmTasks('grunt-contrib-copy');
	grunt.loadNpmTasks('grunt-contrib-clean');
	grunt.loadNpmTasks('grunt-concat-css');
	grunt.loadNpmTasks('grunt-text-replace');
	grunt.loadNpmTasks('grunt-rename-util');
	grunt.loadNpmTasks('grunt-jsonminify');

	// Default task(s).
	grunt.registerTask('default', ['clean','concat','concat_css','cssmin','replace','copy:dist','uglify']);
	grunt.registerTask('dev', ['clean','concat','concat_css','replace','cssmin','copy','jsonminify','rename']);

};