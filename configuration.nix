# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Audio
      <musnix>
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  musnix.enable = true;
  musnix.kernel.optimize = true;
  musnix.kernel.realtime = true;
  musnix.das_watchdog.enable = true;

  # CONFIG THIS LATER--NO IDEA IF THIS IS CORRECT
  # #############################################
  musnix.rtirq = {
    resetAll = 1;
    prioLow = 0;
    prioHigh = 99;
    enable = true;
    nameList = "hpet rtc0 snd";
  };

  musnix.soundcardPciId = "01:00.0";

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };

  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];


  networking.hostName = "flynix";

  time.timeZone = "America/Chicago";

  users.users.gwohl = {
    isNormalUser = true;
    home = "/home/gwohl";
    description = "Andrew A. Grathwohl";
    shell = pkgs.zsh;
    extraGroups = [ "jackaudio" "networkmanager" "audio" "wheel" "docker" "fuse" "media" ];
  };

  nix.trustedUsers = [ "root" "gwohl" ];

  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s25.useDHCP = true;
  networking.interfaces.enp4s0.useDHCP = true;
  networking.interfaces.enp5s0.useDHCP = true;

  services.smartd = {
    enable = true;
    autodetect = true;
    notifications = {
      x11.enable = true;
      wall.enable = true;
    };
  };

  # Configure keymap in X11
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.windowManager.i3 = {
  	enable = true;
    extraPackages = with pkgs; [
		dmenu #application launcher most people use
		i3status # gives you the default i3 status bar
		i3lock #default i3 screen locker
		i3blocks #if you are planning on using i3blocks over i3status
	];
  };
  services.xserver.layout = "us";
  services.xserver.libinput.enable = true;
  services.xserver.autorun = false;
  services.xserver.dpi = 110;
  services.xserver.enableCtrlAltBackspace = true;

  services.xserver.displayManager = {
    defaultSession = "none+i3";
    autoLogin = {
      enable = true;
      user = "gwohl";
    };
  };

  services.picom = {
    enable = true;
    activeOpacity = 1.0;
    inactiveOpacity = 1.0;
    menuOpacity = 0.8;
    backend = "xrender";
  };

  services.fstrim.enable = true;
  services.fwupd.enable = true;


  ###########################
  #########i give up#########
  services.mpd.enable = false;
  services.mpd.extraConfig = ''
    audio_output {
        #type "alsa"
        #name "my ALSA device"
        #device "hw:0"
        #type "jack"
        #type            "pulse"
        #name            "pulse audio"
    }
  '';
  services.mpd.musicDirectory = "/mnt/datadaddy/Music";
  services.mpd.network.listenAddress = "any"; # allow to control from any host


  services.mopidy = {
    enable = false;
    extensionPackages = [ pkgs.mopidy-local pkgs.mopidy-mpd pkgs.mopidy-podcast
    pkgs.mopidy-moped pkgs.mopidy-iris ];
    configuration = ''
      [audio]
      output = pulsesink
      [local]
      media_dir = /mnt/datadaddy/Music
    '';
  };
#############################################

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };


  # Enable the X11 windowing system.
  #services.xserver.enable = true;
  #hardware.nvidia.powerManagement.enable = true;
  hardware.nvidia.nvidiaPersistenced = true;

  # Enable sound.
  sound.enable = true;

  hardware.video.hidpi.enable = true;

  services.jack = {
    jackd = {
      enable = true;
      extraOptions = [ "-P95" "-R" "-u" "-dalsa" "-dhw:HDSPMx0a922c,0" "-r48000" "-p64" "-n2" ];
    };
    # support ALSA only programs via ALSA JACK PCM plugin
    alsa.enable = true;
    alsa.support32Bit = true;
    # support ALSA only programs via loopback device (supports programs like Steam)
    loopback = {
      enable = false;
      # buffering parameters for dmix device to work with ALSA only semi-professional sound programs
      #dmixConfig = ''
      #  period_size 2048
      #'';
    };
  };

  services.thermald.enable = true;


  services.fail2ban = {
    enable = true;

    jails.DEFAULT =
    ''
      bantime  = 3600
    '';

    jails.sshd =
    ''
      filter = sshd
      maxretry = 4
      action   = iptables[name=ssh, port=ssh, protocol=tcp]
      enabled  = true
    '';

    jails.sshd-ddos =
    ''
      filter = sshd-ddos
      maxretry = 2
      action   = iptables[name=ssh, port=ssh, protocol=tcp]
      enabled  = true
    '';

    jails.postfix =
    ''
      filter   = postfix
      maxretry = 3
      action   = iptables[name=postfix, port=smtp, protocol=tcp]
      enabled  = true
    '';

    jails.postfix-sasl =
    ''
      filter   = postfix-sasl
      maxretry = 3
      action   = iptables[name=postfix, port=smtp, protocol=tcp]
      enabled  = true
    '';

    jails.postfix-ddos =
    ''
      filter   = postfix-ddos
      maxretry = 3
      action   = iptables[name=postfix, port=submission, protocol=tcp]
      bantime  = 7200
      enabled  = true
    '';
  };

  environment.etc."fail2ban/filter.d/postfix-ddos.conf".text =
  ''
    [Definition]
    failregex = lost connection after EHLO from \S+\[<HOST>\]
  '';

  # Limit stack size to reduce memory usage
  systemd.services.fail2ban.serviceConfig.LimitSTACK = 256 * 1024;

  programs.mosh.enable = true;

  programs.noisetorch.enable = true;

  # services.xserver.xkbOptions = "eurosign:e";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  #   firefox
  # ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.iftop.enable = true;
  programs.iotop.enable = true;
  programs.gnupg = {
    agent = {
      enable = true;
      enableBrowserSocket = true;
      enableSSHSupport = true;
    };
  };
  programs.dconf.enable = true;

  programs.fish.enable = false;

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch";
      upgrade = "sudo nixos-rebuild switch --upgrade";
    };
    ohMyZsh = {
      enable = true;
      plugins = [ "themes" "tmux" "vault" "vi-mode" "taskwarrior" "rsync" "npm"
      "pip" "cp" "git" "colored-man-pages" "command-not-found" "extract" "aws" ];
      theme = "fletcherm"; # "ys" "robbyrussell"
    };
  };

  programs.neovim = {
    defaultEditor = true;
    enable = true;
    viAlias = false;
    vimAlias = true;
    configure = {
      plug.plugins = with pkgs.vimPlugins; [
        vim-lastplace vim-nix galaxyline-nvim gitsigns-nvim glow-nvim
        i3config-vim indent-blankline-nvim nvim-lsputils lsp-colors-nvim lsp-status-nvim
        lspsaga-nvim markdown-preview-nvim nvim-lspconfig nvim-lightbulb
        nvim-treesitter nvim-web-devicons popup-nvim scrollbar-nvim trouble-nvim
        todo-comments-nvim wal-vim webapi-vim barbar-nvim nvim-colorizer-lua
        defx-git defx-icons defx-nvim diagnostic-nvim nvim-nonicons plenary-nvim
        bufferline-nvim popfix vim-toml telescope-nvim telescope-symbols-nvim
        dashboard-nvim fzf-lsp-nvim lsp_signature-nvim lspkind-nvim lualine-nvim
        vim-better-whitespace vista-vim vim-devicons nvim-autopairs
        papercolor-theme completion-nvim completion-buffers
        completion-treesitter nvim-tree-lua nvim-ts-rainbow glow-nvim
        (nvim-treesitter.withPlugins (
          plugins: pkgs.tree-sitter.allGrammars
        ))
      ];
    customRC = ''
      set termguicolors
      set guioptions-=m
      set guioptions-=T
      set nocursorcolumn
      set number
      set autoread
      set guicursor=
      set nowb
      set noswapfile
      set encoding=utf8
      set wildmenu
      set ruler
      set cmdheight=2
      set backspace=eol,start,indent
      set whichwrap+=<,>,h,l
      set textwidth=80
      set linebreak
      set nolist
      set nowrap
      set breakindent
      set lazyredraw
      set mouse=a
      set noshowmode
      set expandtab
      set tabstop=2
      set softtabstop=2
      set shiftwidth=2
      set smarttab
      set autoindent
      set shiftround
      set showmatch
      set gdefault
      set magic
      set noerrorbells
      set novisualbell
      syntax enable
      set background=dark
      colorscheme PaperColor
      autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()
      highlight NvimTreeFolderIcon guibg=blue
      "let g:rainbow_active = 1
      "let g:nvim_tree_ignore = [ '.git', 'node_modules', '.cache' ] "empty by default
      let g:nvim_tree_gitignore = 1 "0 by default
      let g:nvim_tree_quit_on_open = 1 "0 by default, closes the tree when you open a file
      let g:nvim_tree_indent_markers = 1 "0 by default, this option shows indent markers when folders are open
      "let g:nvim_tree_hide_dotfiles = 1 "0 by default, this option hides files and folders starting with a dot `.`
      let g:nvim_tree_git_hl = 1 "0 by default, will enable file highlight for git attributes (can be used without the icons).
      let g:nvim_tree_highlight_opened_files = 1 "0 by default, will enable folder and file icon highlight for opened files/directories.
      let g:nvim_tree_root_folder_modifier = ':~' "This is the default. See :help filename-modifiers for more options
      let g:nvim_tree_add_trailing = 1 "0 by default, append a trailing slash to folder names
      let g:nvim_tree_group_empty = 1 " 0 by default, compact folders that only contain a single folder into one node in the file tree
      let g:nvim_tree_disable_window_picker = 1 "0 by default, will disable the window picker.
      let g:nvim_tree_icon_padding = ' ' "one space by default, used for rendering the space between the icon and the filename. Use with caution, it could break rendering if you set an empty string depending on your font.
      let g:nvim_tree_symlink_arrow = ' >> ' " defaults to ' ➛ '. used as a separator between symlinks' source and target.
      let g:nvim_tree_respect_buf_cwd = 1 "0 by default, will change cwd of nvim-tree to that of new buffer's when opening nvim-tree.
      let g:nvim_tree_create_in_closed_folder = 0 "1 by default, When creating files, sets the path of a file when cursor is on a closed folder to the parent folder when 0, and inside the folder when 1.
      let g:nvim_tree_refresh_wait = 500 "1000 by default, control how often the tree can be refreshed, 1000 means the tree can be refresh once per 1000ms.
      let g:nvim_tree_window_picker_exclude = {
          \   'filetype': [
          \     'notify',
          \     'packer',
          \     'qf'
          \   ],
          \   'buftype': [
          \     'terminal'
          \   ]
          \ }
      " Dictionary of buffer option names mapped to a list of option values that
      " indicates to the window picker that the buffer's window should not be
      " selectable.
      let g:nvim_tree_special_files = { 'README.md': 1, 'Makefile': 1, 'MAKEFILE': 1 } " List of filenames that gets highlighted with NvimTreeSpecialFile
      let g:nvim_tree_show_icons = {
          \ 'git': 1,
          \ 'folders': 0,
          \ 'files': 0,
          \ 'folder_arrows': 0,
          \ }
      "If 0, do not show the icons for one of 'git' 'folder' and 'files'
      "1 by default, notice that if 'files' is 1, it will only display
      "if nvim-web-devicons is installed and on your runtimepath.
      "if folder is 1, you can also tell folder_arrows 1 to show small arrows next to the folder icons.
      "but this will not work when you set indent_markers (because of UI conflict)

      " default will show icon by default if no icon is provided
      " default shows no icon by default
      let g:nvim_tree_icons = {
          \ 'default': '',
          \ 'symlink': '',
          \ 'git': {
          \   'unstaged': "✗",
          \   'staged': "✓",
          \   'unmerged': "",
          \   'renamed': "➜",
          \   'untracked': "★",
          \   'deleted': "",
          \   'ignored': "◌"
          \   },
          \ 'folder': {
          \   'arrow_open': "",
          \   'arrow_closed': "",
          \   'default': "",
          \   'open': "",
          \   'empty': "",
          \   'empty_open': "",
          \   'symlink': "",
          \   'symlink_open': "",
          \   }
          \ }

      nnoremap <C-n> :NvimTreeToggle<CR>
      nnoremap <leader>r :NvimTreeRefresh<CR>
      nnoremap <leader>n :NvimTreeFindFile<CR>
      " NvimTreeOpen, NvimTreeClose, NvimTreeFocus and NvimTreeResize are also available if you need them

      """""""""""""""""""""""""""""""""""""""" `bufferline` config
      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " NOTE: If barbar's option dict isn't created yet, create it
      let bufferline = get(g:, 'bufferline', {})

      " New tabs are opened next to the currently selected tab.
      " Enable to insert them in buffer number order.
      let bufferline.add_in_buffer_number_order = v:false

      " Enable/disable animations
      let bufferline.animation = v:true

      " Enable/disable auto-hiding the tab bar when there is a single buffer
      let bufferline.auto_hide = v:false

      " Enable/disable current/total tabpages indicator (top right corner)
      let bufferline.tabpages = v:true

      " Enable/disable close button
      let bufferline.closable = v:true

      " Enables/disable clickable tabs
      "  - left-click: go to buffer
      "  - middle-click: delete buffer
      let bufferline.clickable = v:true

      " Enable/disable icons
      " if set to 'buffer_number', will show buffer number in the tabline
      " if set to 'numbers', will show buffer index in the tabline
      " if set to 'both', will show buffer index and icons in the tabline
      let bufferline.icons = v:true

      " Sets the icon's highlight group.
      " If false, will use nvim-web-devicons colors
      let bufferline.icon_custom_colors = v:false

      " Configure icons on the bufferline.
      let bufferline.icon_separator_active = '▎'
      let bufferline.icon_separator_inactive = '▎'
      let bufferline.icon_close_tab = ''
      let bufferline.icon_close_tab_modified = '●'
      let bufferline.icon_pinned = '車'

      " If true, new buffers will be inserted at the start/end of the list.
      " Default is to insert after current buffer.
      let bufferline.insert_at_start = v:false
      let bufferline.insert_at_end = v:false

      " Sets the maximum padding width with which to surround each tab.
      let bufferline.maximum_padding = 4

      " Sets the maximum buffer name length.
      let bufferline.maximum_length = 30

      " If set, the letters for each buffer in buffer-pick mode will be
      " assigned based on their name. Otherwise or in case all letters are
      " already assigned, the behavior is to assign letters in order of
      " usability (see order below)
      let bufferline.semantic_letters = v:true

      " New buffer letters are assigned in this order. This order is
      " optimal for the qwerty keyboard layout but might need adjustement
      " for other layouts.
      let bufferline.letters =
        \ 'asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERUTYQP'

      " Sets the name of unnamed buffers. By default format is "[Buffer X]"
      " where X is the buffer number. But only a static string is accepted here.
      let bufferline.no_name_title = v:null
      let g:dashboard_default_executive ='telescope'

      nnoremap <silent> gd <cmd>lua require'lspsaga.provider'.preview_definition()<CR>
      nnoremap <silent><leader>cd <cmd>lua require'lspsaga.diagnostic'.show_line_diagnostics()<CR>
      nnoremap <silent> <leader>cd :Lspsaga show_line_diagnostics<CR>
      nnoremap <silent><leader>cc <cmd>lua require'lspsaga.diagnostic'.show_cursor_diagnostics()<CR>
      nnoremap <silent> [e <cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_prev()<CR>
      nnoremap <silent> ]e <cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_next()<CR>

      let g:webdevicons_enable = 1

      lua <<EOF


      if vim.fn.has('nvim-0.5.1') == 1 then
          vim.lsp.handlers['textDocument/codeAction'] = require'lsputil.codeAction'.code_action_handler
          vim.lsp.handlers['textDocument/references'] = require'lsputil.locations'.references_handler
          vim.lsp.handlers['textDocument/definition'] = require'lsputil.locations'.definition_handler
          vim.lsp.handlers['textDocument/declaration'] = require'lsputil.locations'.declaration_handler
          vim.lsp.handlers['textDocument/typeDefinition'] = require'lsputil.locations'.typeDefinition_handler
          vim.lsp.handlers['textDocument/implementation'] = require'lsputil.locations'.implementation_handler
          vim.lsp.handlers['textDocument/documentSymbol'] = require'lsputil.symbols'.document_handler
          vim.lsp.handlers['workspace/symbol'] = require'lsputil.symbols'.workspace_handler
      else
          local bufnr = vim.api.nvim_buf_get_number(0)

          vim.lsp.handlers['textDocument/codeAction'] = function(_, _, actions)
              require('lsputil.codeAction').code_action_handler(nil, actions, nil, nil, nil)
          end

          vim.lsp.handlers['textDocument/references'] = function(_, _, result)
              require('lsputil.locations').references_handler(nil, result, { bufnr = bufnr }, nil)
          end

          vim.lsp.handlers['textDocument/definition'] = function(_, method, result)
              require('lsputil.locations').definition_handler(nil, result, { bufnr = bufnr, method = method }, nil)
          end

          vim.lsp.handlers['textDocument/declaration'] = function(_, method, result)
              require('lsputil.locations').declaration_handler(nil, result, { bufnr = bufnr, method = method }, nil)
          end

          vim.lsp.handlers['textDocument/typeDefinition'] = function(_, method, result)
              require('lsputil.locations').typeDefinition_handler(nil, result, { bufnr = bufnr, method = method }, nil)
          end

          vim.lsp.handlers['textDocument/implementation'] = function(_, method, result)
              require('lsputil.locations').implementation_handler(nil, result, { bufnr = bufnr, method = method }, nil)
          end

          vim.lsp.handlers['textDocument/documentSymbol'] = function(_, _, result, _, bufn)
              require('lsputil.symbols').document_handler(nil, result, { bufnr = bufn }, nil)
          end

          vim.lsp.handlers['textDocument/symbol'] = function(_, _, result, _, bufn)
              require('lsputil.symbols').workspace_handler(nil, result, { bufnr = bufn }, nil)
          end
      end
      EOF

            " Special
      let wallpaper  = "/home/gwohl/Pictures/1624873033603-0.jpg"
      let background = "#0a0603"
      let foreground = "#a8c4cb"
      let cursor     = "#a8c4cb"

      " Colors
      let color0  = "#0a0603"
      let color1  = "#919110"
      let color2  = "#12a4a4"
      let color3  = "#15c2ac"
      let color4  = "#16cd46"
      let color5  = "#1174a0"
      let color6  = "#176fd1"
      let color7  = "#a8c4cb"
      let color8  = "#75898e"
      let color9  = "#919110"
      let color10 = "#12a4a4"
      let color11 = "#15c2ac"
      let color12 = "#16cd46"
      let color13 = "#1174a0"
      let color14 = "#176fd1"
      let color15 = "#a8c4cb"

      lua << EOF
        require'nvim-web-devicons'.setup {
          default = true;
        }
        require('trouble').setup {
          -- your configuration comes here
          -- or leave it empty to use the default settings
          -- refer to the configuration section below
        }
        local gl = require('galaxyline')
        local gls = gl.section
        local extension = require('galaxyline.provider_extensions')
        local function lsp_status(status)
            shorter_stat = ""
            for match in string.gmatch(status, "[^%s]+")  do
                err_warn = string.find(match, "^[WE]%d+", 0)
                if not err_warn then
                    shorter_stat = shorter_stat .. ' ' .. match
                end
            end
            return shorter_stat
        end

        local function trailing_whitespace()
            local trail = vim.fn.search("\\s$", "nw")
            if trail ~= 0 then
                return ' '
            else
                return nil
            end
        end

        local custom_condition = {
          buffer_not_empty = function()
              if vim.fn.empty(vim.fn.expand "%:t") ~= 1 then
                  return true
              end
              return false
          end,
          wide_window_condition = function()
              return vim.fn.winwidth "%" >= 160 -- 160 is a somewhat random number. it felt nice.
            end,
        }
        TrailingWhiteSpace = trailing_whitespace
        gls.left[1]= {
          FileSize = {
            provider = 'FileSize',
            condition = function()
              if vim.fn.empty(vim.fn.expand('%:t')) ~= 1 then
                return true
              end
              return false
              end,
            icon = '   ',
            highlight = {color3,color5},
            separator = '',
            separator_highlight = {color2,color4},
          }
        }
        gls.left[2] ={
          FileIcon = {
            provider = 'FileIcon',
            condition = buffer_not_empty,
            highlight =
              {require('galaxyline.provider_fileinfo').get_file_icon_color,background},
          },
        }
        gls.left[3] = {
          FileName = {
            provider = {'FileName','FileSize'},
            condition = buffer_not_empty,
            highlight = {foreground,background,'bold'}
          }
        }
        gls.left[4] = {
          GitIcon = {
            provider = function() return '  ' end,
            condition = require('galaxyline.provider_vcs').check_git_workspace,
            highlight = {color6,background},
          }
        }
        gls.left[5] = {
          GitBranch = {
            provider = 'GitBranch',
            condition = require('galaxyline.provider_vcs').check_git_workspace,
            highlight = {'#8FBCBB',background,'bold'},
          }
        }
        gls.left[6] = {
          DiffAdd = {
            provider = 'DiffAdd',
            condition = checkwidth,
            icon = ' ',
            highlight = {color8,cursor},
          }
        }
        gls.left[7] = {
          DiffModified = {
            provider = 'DiffModified',
            condition = checkwidth,
            icon = ' ',
            highlight = {color6,cursor},
          }
        }
        gls.left[8] = {
          DiffRemove = {
            provider = 'DiffRemove',
            condition = checkwidth,
            icon = ' ',
            highlight = {color14,cursor},
          }
        }
        gls.left[9] = {
          LeftEnd = {
            provider = function() return '' end,
            separator = '',
            separator_highlight = {background,cursor},
            highlight = {cursor,cursor}
          }
        }

        gls.left[10] = {
            TrailingWhiteSpace = {
            provider = TrailingWhiteSpace,
            icon = '  ',
            highlight = {color9,background},
            }
        }

        gls.left[11] = {
          DiagnosticError = {
            provider = 'DiagnosticError',
            icon = '  ',
            highlight = {color14,background}
          }
        }
        gls.left[12] = {
          Space = {
            provider = function () return ' ' end
          }
        }
        gls.left[13] = {
          DiagnosticWarn = {
            provider = 'DiagnosticWarn',
            icon = '  ',
            highlight = {color9,background},
          }
        }
        gls.right[1]= {
          FileFormat = {
            provider = 'FileFormat',
            separator = ' ',
            separator_highlight = {background,cursor},
            highlight = {foreground,cursor,'bold'},
          }
        }
        gls.right[4] = {
          LineInfo = {
            provider = 'LineColumn',
            separator = ' | ',
            separator_highlight = {color12,cursor},
            highlight = {foreground,cursor},
          },
        }
        gls.right[5] = {
          PerCent = {
            provider = 'LinePercent',
            separator = ' ',
            separator_highlight = {cursor,cursor},
            highlight = {color5,color4,'bold'},
          }
        }
        gls.right[6] = {
            ShowLspClient = {
                provider = function()
                    local clients = vim.lsp.buf_get_clients(0)
                    local count = vim.tbl_count(clients)
                    return "(" .. count .. ")"
                end,
                condition = function()
                    local disabledFiletypes = { [" "] = true }
                    if disabledFiletypes[vim.bo.filetype] then
                        return false
                    end
                    return true and custom_condition.wide_window_condition()
                end,
                highlight = { color0, background },
            },
        }
        gls.short_line_left[1] = {
          BufferType = {
            provider = 'FileTypeName',
            separator = '',
            condition = has_file_type,
            separator_highlight = {color13,background},
            highlight = {foreground,color13}
          }
        }
        gls.short_line_right[1] = {
          BufferIcon = {
            provider= 'BufferIcon',
            separator = '',
            condition = has_file_type,
            separator_highlight = {color13,background},
            highlight = {foreground,color13}
          }
        }
        local saga = require 'lspsaga'
        saga.init_lsp_saga()
        require('lspconfig').pyright.setup{}
        require'lspconfig'.vuels.setup{}
        require'lspconfig'.jsonls.setup{}
        require'lspconfig'.tsserver.setup{}
        require'lspconfig'.tailwindcss.setup{}
        require'lspconfig'.svelte.setup{}
        require'lspconfig'.html.setup{}
        require'lspconfig'.dockerls.setup{}
        require('gitsigns').setup()
        require('colorizer').setup()
        require('lspkind').init({
          with_text = true,
          preset = 'codicons',
        })
        require'nvim-treesitter.configs'.setup {
          ensure_installed = {
            "javascript", "tsx", "svelte", "supercollider", "python", "rust", "vue"
          },
          ignore_install = {
            "elm", "fortran", "ocaml_interface", "scss", "vue"
          },
          indent = {
            enable = true,
          },
          highlight = {
            enable = true,
            additional_vim_regex_highlighting = true,
          },
          rainbow = {
            enable = true,
            extended_mode = true,
            max_file_lines = nil,
          },
        }
        require('nvim-autopairs').setup({
          disable_filetype = { "TelescopePrompt" , "vim" },
        })
      EOF
    '';
  };
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  #programs.wireshark.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

  environment.systemPackages = with pkgs; [
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    arandr               # simple GUI for xrandr
    asciinema            # record the terminal
    alacritty
    atop
    aws
    betterlockscreen
    blugon
    bpytop
    dunst
    feh
    filelight
    firefox
    fuse
    gcc
    gimp
    git
    glow
    htop
    imagemagick
    libnfs
    libnotify
    libreoffice
    libsodium
    lsof
    jq
    mosh
    nfs-ganesha
    nfsUtils
    nfstrace
    nodejs
    ntfs3g
    openvpn
    pandoc
    pass
    pdf2svg
    python
    python3
    pyright
    ranger
    readline
    rofi
    signal-desktop
    simple-scan
    speedtest-cli
    taskwarrior
    unclutter
    unzip
    usbutils
    wget
    whois
    xorg.xwininfo
    xorg.xorgproto
    zbar
    ####AUDIO
    alsaLib
    alsaPlugins
    alsaTools
    alsaUtils
    audiowaveform
    bitmeter
    carla
    fftwFloat
    libjack2
    libopus
    libsamplerate
    libshout
    libvorbis
    jack2
    jack_capture
    jackmix
    jackmeter
    japa
    meterbridge
    ncmpcpp
    non
    pavucontrol
    pkg-config
    rubberband
    sox
    soxr
    supercollider
    timemachine
    xjadeo
    wine-staging
    winetricks
    wireshark
    zita-ajbridge
    zita-at1
    zita-njbridge
    ####MEDIA
    ffmpeg-full
    ffms
    freetype
    gst_all_1.gstreamer
    gst_all_1.gst-libav
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-devtools
    gst_all_1.gst-rtsp-server
    gst_all_1.gstreamermm
    gst_all_1.gst-vaapi
    libass
    libarchive
    libpng
    libdrm
    libcaca
    libcdio
    libcdio-paranoia
    libuchardet
    libvdpau-va-gl
    xorg.libXext
    libva1-full
    libva-utils
    mpv-with-scripts
    mpvScripts.autoload
    nv-codec-headers
    vaapiVdpau
    vapoursynth
    ####MISC
    neomutt
    thunderbird
    weechat
    weechatScripts.weechat-autosort
    weechatScripts.weechat-matrix
    weechatScripts.weechat-matrix-bridge
    weechatScripts.weechat-notify-send
    ####NUR
    nur.repos.dan4ik605743.bitmap-fonts
    ###libsodium stuff
    #### from cabal-desktop nix-shell
    clang
    gnumake
    libtool
    autoconf
    automake
    m4
    libgpgerror
    libuuid
    libcap
    glib
    glibc
  ];
	environment.variables = {
	    EDITOR = "nvim";
	    FREETYPE_PROPERTIES = "truetype:interpreter-version=38";
	    HISTCONTROL = "ignoredups:erasedups";
	    QT_LOGGING_RULES = "*=false";
	};

  # Enable Redshift.
  services.redshift = {
    enable = true;
    brightness = {
      day = "1";
      night = "0.70";
    };
    temperature = {
      day = 6500;
      night = 3500;
    };
  };

  programs.atop = {
    atopService.enable = true;
    atopgpu.enable = true;
    setuidWrapper.enable = true;
  };

  location = {
    latitude = 35.9356;
    longitude = -87.2177;
    provider = "geoclue2";
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };


  programs.chromium = {
    enable = true;
    extensions = [
      "chlffgpmiacpedhhbkiomidkjlcfhogd" # pushbullet
      "mbniclmhobmnbdlbpiphghaielnnpgdp" # lightshot
      "gcbommkclmclpchllfjekcdonpmejbdp" # https everywhere
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
    ];
    extraOpts = {
      "BrowserSignin" = 0;
      "SyncDisabled" = true;
      "PasswordManagerEnabled" = false;
      "SpellcheckEnabled" = true;
      "SpellcheckLanguage" = [ "en-US" ];
    };
    defaultSearchProviderSuggestURL = "https://encrypted.google.com/complete/search?output=chrome&q={searchTerms}";
    defaultSearchProviderSearchURL = "https://encrypted.google.com/search?q={searchTerms}&{google:RLZ}{google:originalQueryForSuggestion}{google:assistedQueryStats}{google:searchFieldtrialParameter}{google:searchClient}{google:sourceId}{google:instantExtendedEnabledParameter}ie={inputEncoding}";
  };

  fonts = {
    fontconfig.enable = true;
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
    	corefonts
      nerdfonts
      google-fonts
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts
      dina-font
      proggyfonts
      font-awesome-ttf
      siji
    ];
  };

  environment.sessionVariables = rec {
    XDG_CACHE_HOME  = "\${HOME}/.cache";
    XDG_CONFIG_HOME = "\${HOME}/.config";
    XDG_BIN_HOME    = "\${HOME}/.local/bin";
    XDG_DATA_HOME   = "\${HOME}/.local/share";

    NODE_PATH       = "\${HOME}/.npm-global/lib/node_modules";
    PATH = [
      "\${XDG_BIN_HOME}"
      "\${HOME}/.npm-global/bin"
    ];
    JACK_NO_START_SERVER = "1";
    JACK_NO_AUDIO_RESERVATION = "1";

    BROWSER = "firefox";
  };
  environment.shellAliases = {
    ytdl = "yt-dlp -N 10 --yes-playlist --download-archive 'archive.log' -i --add-metadata --all-subs -f '(bestvideo[vcodec^=av01][height>=1080][fps>30]/bestvideo[vcodec=vp9.2][height>=1080][fps>30]/bestvideo[vcodec=vp9][height>=1080][fps>30]/bestvideo[vcodec^=av01][height>=1080]/bestvideo[vcodec=vp9.2][height>=1080]/bestvideo[vcodec=vp9][height>=1080]/bestvideo[height>=1080]/bestvideo[vcodec^=av01][height>=720][fps>30]/bestvideo[vcodec=vp9.2][height>=720][fps>30]/bestvideo[vcodec=vp9][height>=720][fps>30]/bestvideo[vcodec^=av01][height>=720]/bestvideo[vcodec=vp9.2][height>=720]/bestvideo[vcodec=vp9][height>=720]/bestvideo[height>=720]/bestvideo)+(bestaudio[acodec=opus]/bestaudio)/best' --merge-output-format mkv";
  };

  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  hardware.pulseaudio.extraConfig = ''
    load-module module-jack-sink channels=2 connect=true
    load-module module-jack-source channels=2 connect=true
  '';
  hardware.pulseaudio.daemon.config = {realtime-scheduling = "yes";};
  systemd.user.services.pulseaudio.after = [ "jack.service" ];
  systemd.user.services.pulseaudio.environment = {
    JACK_PROMISCUOUS_SERVER = "jackaudio";
  };

  nix = {
    buildCores = 6;
    maxJobs = 5;
  };

  # Enable all the firmware
  hardware.enableAllFirmware = true;
  # Enable all the firmware with a license allowing redistribution. (i.e. free firmware and firmware-linux-nonfree)
  hardware.enableRedistributableFirmware = true;

  boot.cleanTmpDir = true;

  # Enable microcode updates for Intel CPU
  hardware.cpu.intel.updateMicrocode = true;

  boot.blacklistedKernelModules = [ "snd_hda_codec_realtek" "snd_hda_codec_hdmi" "snd_hda_intel" ];

  security.sudo.wheelNeedsPassword = false;
}
