import os
import sys
import re

def sanitize_filename(filename):
    # Esta regex substitui qualquer sequência de caracteres de "espaço" (incluindo espaços inquebráveis, tabs, etc.)
    # por nada, removendo-os completamente.
    # \s no regex padrão do Python cobre [ \t\n\r\f\v] e também espaços Unicode dependendo da versão.
    return re.sub(r'\s+', '', filename)

def rename_files(root_dir, dry_run=True):
    print(f"{'[MODO DE TESTE]' if dry_run else '[MODO DE EXECUÇÃO]'} Iniciando renomeação em: {root_dir}")
    print("--------------------------------------------------")
    
    renamed_count = 0
    skipped_count = 0
    error_count = 0

    # Normaliza o caminho para evitar problemas com barras no final ou caminhos relativos
    root_dir = os.path.abspath(root_dir)

    for root, dirs, files in os.walk(root_dir):
        for filename in files:
            # Verifica se o nome contém qualquer tipo de caractere de espaço em branco
            if re.search(r'\s', filename):
                old_path = os.path.join(root, filename)
                new_filename = sanitize_filename(filename)
                new_path = os.path.join(root, new_filename)

                if os.path.exists(new_path) and old_path != new_path:
                    print(f"  Aviso: '{filename}' -> '{new_filename}' já existe. Ignorando.")
                    skipped_count += 1
                else:
                    if dry_run:
                        print(f"  PREVIEW: '{filename}' -> '{new_filename}'")
                        renamed_count += 1 # Contamos como "potencialmente renomeado" no preview
                    else:
                        try:
                            os.rename(old_path, new_path)
                            print(f"  Renomeado: '{filename}' -> '{new_filename}'")
                            renamed_count += 1
                        except OSError as e:
                            print(f"  Erro ao renomear '{filename}': {e}")
                            error_count += 1
            else:
                skipped_count += 1

    print("--------------------------------------------------")
    print(f"{'[MODO DE TESTE]' if dry_run else '[MODO DE EXECUÇÃO]'} Concluído.")
    print(f"  Arquivos identificados/renomeados: {renamed_count}")
    print(f"  Arquivos sem espaços (ignorados): {skipped_count}")
    print(f"  Erros: {error_count}")

if __name__ == "__main__":
    # Padrão é o diretório atual
    target_directory = "."
    dry_run_mode = True

    # Lógica de argumentos mais flexível
    args = sys.argv[1:]
    
    # Se houver argumentos, o primeiro pode ser o diretório ou a flag
    for arg in args:
        if arg == "--execute":
            dry_run_mode = False
        elif not arg.startswith("--"):
            target_directory = arg

    if not os.path.isdir(target_directory):
        print(f"Erro: O caminho '{target_directory}' não é um diretório válido.")
        sys.exit(1)

    rename_files(target_directory, dry_run=dry_run_mode)
    
    if dry_run_mode:
        print("\n*** ATENÇÃO: Nenhuma alteração foi feita ainda. ***")
        print("Para aplicar as mudanças, execute o comando adicionando '--execute':")
        print(f"python3 {sys.argv[0]} \"{target_directory}\" --execute")
